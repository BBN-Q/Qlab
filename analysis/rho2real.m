function out = rho2real(rho)

%Helper function to go from conventional density matrix to real density
%matrix (matrix form of Pauli decomposition)
%
% See arXiv:quant-ph/0302176 for details

dim = size(rho,1);
n = log2(dim);

xBasis = cell(dim,1);
yBasis = cell(dim,1);

X = [0,1;1,0]; Y = [0,-1i;1i,0]; I = eye(2);

for ct = 1:dim
    binvec = bitget(ct-1, 1:n);
    xBasis{ct} = 1;
    yBasis{ct} = 1;
    for ct2 = 1:n
        if binvec(ct2)
            xBasis{ct} = kron(X, xBasis{ct});
            yBasis{ct} = kron(Y, yBasis{ct});
        else
            xBasis{ct} = kron(I, xBasis{ct});
            yBasis{ct} = kron(I, yBasis{ct});
        end
    end
end

out = zeros(dim,dim);

for rowct = 1:dim
    for colct = 1:dim
        tmpMat = xBasis{rowct}*yBasis{colct};
        %Hack to get rid of angle
        %This can be handled with a proper multiplication rule
        tmpMat = exp(-1j*angle(tmpMat(1,1)))*tmpMat;
        out(rowct,colct) = real(trace(rho*tmpMat));
    end
end
