clear all;
s=1;
L=24;   %CRC length
B=20496; %---------------transport block size            
k_cb=8448; %-------------max size of input LDPC Encoder can
k_b=22;
tb=randi([0 1],1,B);    %random transport block generation
R=679/1024; % MCS-9  code rate
nPRBs=100;
G=100*162*2;
actual_code_rate=B/G;
m=2
%% Transport CRC genration



g=input("enter the type of generator polynomial  1.24A 2.24B 3.24C ");

switch g
    case 1
        gen_poly=[24 23 18 17 14 11 10 7 6 5 4 3 1 0];
    case 2
        gen_poly=[24 23 6 5 1 0];
    case 3
        gen_poly=[24 23 21 20 17 15 13 12 8 4 2 1 0];
end

y=zeros(1,25);


for i=1:length(gen_poly)        %generator polynomial binary generation
    p=gen_poly(i);
    y(p+1)=1;
end
y=flip(y);

tb_crc = crc_gen(tb,y); %-------------crc generation 
B=B+24;
tb1=[tb tb_crc];    %-------concatination of transport block and tb_crc


out = crc_val(tb,y,tb_crc); %------validation of tb (just to check)
disp(out);



%% Segmentation

C=ceil(B/(8448-24)); %number of code block segments
B1 = B + (C*L);     %effective transport block length
k1=B1/C;    

Z_c=ceil(k1/k_b);   

%% generating lift size table and choosing the lift size Zc accordingly

LiftSize_m=[];
for i=0:7           %----loop for generating lift size matrix
    x=(2*i)+1;
    var=0;
    j=0;
    while var< 400
        var= x*2^j;
        if var>400
            break
        end
        j=j+1;
        LiftSize_m=[LiftSize_m var];
    end
end
LiftSize_m(1)=[];
LiftSize_m=sort(LiftSize_m);    %---sorting lift size matrix

Lift_Size=LiftSize_m(length(find(Z_c>LiftSize_m))+1);
Z_c=Lift_Size;      % choosing lifting size according to table
k=k_b*Z_c;      %-----size of each code block
F=k-k1;     %---------number of filler bits




%%  bit sequence


i=1;
j=1;
s=1;
c=[];
Pr=zeros(3,24); 
C1=1
while s<=length(tb)         %
while j<=k1-L   % 
        c(i,j)=tb1(s);
        s=s+1;
        j=j+1;
end

if C>1
    if C1<=C
      C1=C1+1;
      Pr(i,:)=crc_gen(c(i,1:k1-L),y);   %--------genrating crc of each code block
      i1=1;
%       while i1<=length(Pr)
%           c(i,j)= Pr(i1);
%           i1=i1+1;
%           j=j+1
%       end
      c(i,j:j+23)=Pr(i,:)   %-------appending cb and cb-crc
      j=j+24;
    end
end
while j<=k  %--------adding filler bits to each code block
    c(i,j)=-1;
    j=j+1;
end

i=i+1;
j=1;
end




%% LDPC ENCODING

nbg = 1; % Base graph 1
nldpcdecits = 25;
%out = LDPCEncode(c',1);




% nbg = 1; % Base graph 1
% nldpcdecits = 25; % Decode with maximum no of iteration
%   
% %----------------------------------LDPC encoding----------------------- ------------------------
%   
ldpc_coded_bits = double(LDPCEncode(c',nbg)); %-----LDPC ENCODING
   

%-----------------------------------------------------------------------------------------

filler_bit_loc=find(ldpc_coded_bits(:,1)==-1);   %saving filler bit locations
ldpc_coded_bits(filler_bit_loc,:)=[];            %removing filler bits
E=G/C;
rate_match=ldpc_coded_bits(1:E,:);
cb_concat=reshape(rate_match,E*C,1);

cb_concat=reshape(cb_concat,size(cb_concat,1)/2,2)'     % interleaving
cb_concat=reshape(cb_concat,[],1)



%-----------------------------------------------------------------------------------------------
mod_output = 2*(cb_concat-0.5);
mod_output_1=reshape(mod_output,2,(E*C)/2)';
mod_output_2=mod_output_1(:,1)+1i*mod_output_1(:,2); %QPSK symbols

noise_power = (10^-5);
noise = sqrt(noise_power)*randn(size(mod_output_2))+1i*sqrt(noise_power)*randn(size(mod_output_2));
rx_sig = mod_output_2 + noise; %  adding  noise to signal

real_llr0 =  abs(-1 + real(rx_sig));   % in-phase  demod
real_llr1 =  abs(1 + real(rx_sig));    % in-phase demod
real_llr = log(real_llr0./real_llr1);      % ldpc decoder requires log(p(r/0)/p(r/1))
img_llr0 =  abs(-1 + imag(rx_sig));   % quadrature phase demod
img_llr1 =  abs(1 + imag(rx_sig));    % quadrature phase demod
img_llr = log(img_llr0./img_llr1);      % ldpc decoder requires log(p(r/0)/p(r/1))

demod_output = real_llr + 1i*img_llr;   % received llr  of qpsk
demod_output_bits=[real(demod_output) imag(demod_output)]
demod_output_bits_1=reshape(demod_output_bits',G,1);    


%------------------------------deinterleaving-----------------------

demod_output_bits_1=reshape(demod_output_bits_1,2,[])   %deinterleaving
demod_output_bits_1=reshape(demod_output_bits_1',[],1)

%-------------------------------rate matching--------------

demod_output_bits_1=reshape(demod_output_bits_1,G/3,3); % block segmenting
demod_output_bits_1=[demod_output_bits_1;zeros(10144,3)];  % adding neutral bits for rate recovery
demod_output_bits_1=[demod_output_bits_1(1:6224,:);zeros(176,3);demod_output_bits_1(6225:20944,:)]  
                            % adding neutral bits in filler bits  positions





%----------------------------------LDPC decoding----------------------- -------------------------

outputbits = double(LDPCDecode(demod_output_bits_1,nbg,nldpcdecits));

errors = find(outputbits - c')  %------FINDING NUMBER OF BITS

 
%% removal of filler bits
 outputbits=outputbits' 
 i=1;
 while i<=C
    
 out_filler_bits_removal(i,:)=outputbits(i,1:k1);   %---------removing filler bits
 i=i+1;
 end
 out_filler_bits_removal = cast(out_filler_bits_removal,"double")
 
 %% CRC validation of code blocks
 
 crc_decode=0;
 i=1;
 while i<=C     %---------loop for validating each code block
 crc_validation= crc_val(out_filler_bits_removal(i,1:k1-L),y,out_filler_bits_removal(i,k1-L+1:k1))
 i=i+1;         
 if crc_validation==0       
     disp('decode failure');    %-----if any code block is not validated => transmission failure
     crc_decode=1;
     break; 
 end
 end
 

 if crc_decode==0       %--------ALL CODE BLOCKS ARE VALIDATED
     code_block_concat=[];  
     i=1;
     while i<=C     %--------loop for removing code block crc and concatenating code blocks
         code_block_concat=[code_block_concat out_filler_bits_removal(i,1:k1-L)];   
         i=i+1;
     end

 end
     tb_crc_val=crc_val(code_block_concat(1,1:B-L),y,code_block_concat(B-L+1:end));
     disp(tb_crc_val);      %-------------validating transport block crc
 
 

 errors= find(code_block_concat(1,1:B-L)-tb)    %-----output message
 









