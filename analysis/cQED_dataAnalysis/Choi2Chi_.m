function [chi] = Choi2Chi_(choi,pauliopts,n)
% Jay Gambetta, March 1st 2011
% 
% takes in a vector of coef and the opts and makes the choi state for for n
% qubits
% Input 
%	raulicoef = a matrix of dim 4^nx4^n containing the expectationd of the pauliopts
%	pauliopts = a cell of dim 4^n containing the pauliopts
%	n = number of qubits
% Output
%   choi = the choi matrix
d=2^n;


basis_mat = zeros(d^4,d^4);
for aa=1:d
    for bb=1:d
        for cc=1:d
            for dd=1:d
                for ll=1:d^2
                    for mm=1:d^2
                        basis_mat(d^3*(aa-1) + d^2*(bb-1) + d*(cc-1) + dd, d^2*(ll-1) + mm)=...
                            pauliopts{ll}(bb,aa)*pauliopts{mm}(dd,cc)/d;
                    end
                end
            end
        end
    end
end

                        
                        



chi = reshape(basis_mat\choi(:),d^2,d^2);

end

