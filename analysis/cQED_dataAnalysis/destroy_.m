function a = destroy_(dim)
% Author Jay Gambetta 
% Feb 28th 2011
%
% creates the destruction operator of a dim dimensional system

a=zeros(dim,dim);
for j=1:dim
    for k=1:dim
        if k - j == 1
            a(j,k)=sqrt(j);
        end
    end
end
a=sparse(a);
