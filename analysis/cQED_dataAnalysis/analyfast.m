%This function provides a Pauli decomposition of a matrix
%It takes only the terms in the density matrix greater than some cutoff and
%then converts from the I+,I-,0,1 basis to X,Y,I,Z
%
% function analyfast(matt,cutoff)

%Written by Colm Ryan Spring 2005
%Updated by Colm Ryan October 2005

function analyfast(matt,cutoff)


%Start the clock
fprintf('Starting to analyse the matrix..........');
tic

%Setup some constants
N = size(matt,2);
n = log2(N);

%Setup some binary conversions
binarynum = zeros(2^n,n);
for ct = 1:1:2^n
        %Work out which basis state
        binct = dec2bin(ct-1,n);
        for k = 1:1:n
            binarynum(ct,k) = str2num(binct(k));
        end
end

%Find the values in the density matrix greater than the cutoff
[r,c] = find(abs(matt)>(cutoff/sqrt(N)));

%Now we just have to do some algebra

%First create the basis states
basis(1,:) = [1/2 0 1/2 1];
basis(4,:) = [1/2 0 -1/2 1];
basis(3,:) = [1/2 2 i/2 3];
basis(2,:) = [1/2 2 -i/2 3];

%Setup the matrix containing the values of the decomposition
decomp = sparse([],[],[],4^n,1,0);

%Initialize display checker
lastdisp = 0;
totlength = length(r);

%Now loop through each term in the density matrix
for ct = 1:1:length(r)
    %Convert the indicies to binary
    rbin = binarynum(r(ct),:);
    cbin = binarynum(c(ct),:);
    
    %Now calculate which basis states we have
    for k = 1:1:n
        tmp(k,:) = basis(2*cbin(k)+rbin(k)+1,:);
    end %k loop


    %Now muyltiply out and add it to the decomp matrix
    for ct2 = 1:1:2^n
        
        %Work out which Pauli term (base 4) and multiplicative factor
        basisct = 0;
        mult = 1;
        for ct3 = 1:1:n
            basisct = tmp(ct3,2*binarynum(ct2,ct3)+2)*4^(n-ct3) + basisct;
            mult = mult*tmp(ct3,2*binarynum(ct2,ct3)+1); 
        end %ct3 loop
        
        %Now add the value to the decomp
        decomp(basisct+1) = matt(r(ct),c(ct))*mult + decomp(basisct+1);
    end %ct2 loop

    clear tmp

    %Write out some progression stuff
    if(ct/totlength - lastdisp > 0.01)
       fprintf('\b\b\b\b\b%3.0f %%',100*ct/totlength)
       lastdisp = ct/totlength;
    end
    
end
fprintf('\n\n');


%Now write out the decomposition
letters = 'IZXY';
clear r c

[r,c] = find(abs(decomp)>cutoff);%*(sqrt(2)^n));

lastdisp = 0;

for ct = 1:1:length(r)
    
    %Determine the basis name (convert to base 4)
    tmpbasisnum = dec2base(r(ct)-1,4,n);
    for k = 1:1:n
            basisnum(k) = str2num(tmpbasisnum(k));
    end
    
    basisname = '';
    for k = 1:1:n
        basisname = [basisname letters(basisnum(k)+1)];
    end
    
    %Write it out
    realdec = real(decomp(r(ct)));%/sqrt(2)^n;
    imagdec = imag(decomp(r(ct)));%/sqrt(2)^n;
    if(abs(realdec)> cutoff & abs(imagdec) > cutoff)
      fprintf('%s = %s\n',basisname,num2str(realdec+i*imagdec));
    elseif(abs(realdec)>cutoff)
      fprintf('%s = %s\n',basisname,num2str(realdec));
    elseif(abs(imagdec)>cutoff)
      fprintf('%s = %si\n',basisname,num2str(imagdec));
    end
end

%Write out the final norm
disp(sprintf('\nFinal norm: %g',full(trace(matt^2))))

%And the time the analysis took
disp(sprintf('\nAnalysis took %f seconds',toc));

return 