function [ M ] = Choi2Liouville_(c)

% author: Marcus da Silva
%
%    L = qip.open_systems.choi_liou_involution(A) shuffles the matrix
%    elements of A such that if A is a Choi matrix, L is the corresponding
%    Liouville matrix (and if A is the Liouville matrix, L is the
%    Choi). We assume a column major Liouvillian representation of
%    the superoperator.
%
%    This operation is an involution -- it is self inverse.

d = sqrt(size(c,1));
M = c;

index = @(a,b) (a-1)*d+b;

for n=1:d,
  for m=1:d,
    for o=1:d,
      for p=n+1:d,
        % this swaps M_{nm,op} with M_{pm,on}
        temp = M( index(n,m), index(o,p) );
        M( index(n,m), index(o,p) ) = ...
            M( index(p,m), index(o,n) );
        M( index(p,m), index(o,n) ) = temp;
      end
    end
  end
end

%Normalization
M = d*M;
