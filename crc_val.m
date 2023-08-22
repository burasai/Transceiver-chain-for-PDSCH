function out = crc_val(ib,y,z)
i=1;
x=[ib z];               % appending the generated crc to input block for validation

z=zeros(1,length(y));   % remainder variable with zeros initially
z=x(i:i+length(y)-1);   % taking the input block first elements into rem

while i<=length(x)-length(y)+1
    while z(1)==0       %  block for removing the zeros in the remainder and adding bits from input block
        if i<length(x)-length(y)+1
            z(1)=[];    % removing the zero in remainder
            z=[z x(i+length(y))]; % appending new bit from input block
            i=i+1;
        else
            z(1)=[];        % if already the last element of input block(crc included) is taken then 
            i=i+1;          % still the first bit is 0 discard it and stop taking bits from input block
            break
        end
    end

   if i<=length(x)-length(y)+1 
       if z(1)==1
           z=bitxor(z,y);       % bit exor of remainder and gen_poly
           z(1)=[];             % discarding the first bit of exor output
       end
   end

    if i<=length(x)-length(y)   
        z=[z x(i+length(y))];   % appending new bit after exor operation
    end
    i=i+1;
    
end

if z==0
    out=1;
else
    out=0;
end

end
