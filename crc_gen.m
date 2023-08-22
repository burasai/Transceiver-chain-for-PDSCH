
function [z] = crc_gen(ib,y)

i=1;
x=[ib zeros(1,length(y)-1)];    % appending zeros at then end of code for crc calculation

z=zeros(1,length(y));           %  variable which store remainder

z=x(i:i+length(y)-1);           %  initializing variable with first bits of code word 

while i<=length(x)-length(y)+1
    while z(1)==0               %  discarding initial zeros & getting input block bit
        if i<length(x)-length(y)+1
            z(1)=[];            % discarding the first bit (since its zero)
            z=[z x(i+length(y))];% appending the new bit from input block
            i=i+1;
        else
            z(1)=[];
            i=i+1;
            break
        end
    end

   if i<=length(x)-length(y)+1  
       if z(1)==1
           z=bitxor(z,y);  %exor operation of remainder and gen_poly
           z(1)=[];
       end
   end

    if i<=length(x)-length(y)
        z=[z x(i+length(y))];   % appending new bits after exor and discarding initial bit
    end
    i=i+1;
    
end
end
