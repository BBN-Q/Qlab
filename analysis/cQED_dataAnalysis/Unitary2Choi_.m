function [ choi ] = Unitary2Choi_(U)
% Jay Gambetta, Dec 19th 2011
% 
% This function calculates the Lioiuville matrix for a unitary matrix 
% 
% Input 
%	unitart = a 2^n x 2^n matrix represent the unitary
% Return
%	Choi

d=size(U,1);
choi=zeros(d^2,d^2);
for ii=1:d
    for jj=1:d
        proj = zeros(d,d);
        proj(ii,jj) = 1;
        choi = choi + kron(proj,U*proj*U')/d;
    end
end

end

