function out = rho2real(rho)

%Helper function to go from conventional density matrix to real density
%matrix (matrix form of Pauli decomposition)
%
% See arXiv:quant-ph/0302176 for details

dim = size(rho,1);
n = log2(dim);

xBasis = cell(dim,1);
yBasis = cell(dim,1);

X = [0,1;1,0]; Y = [0,-1i;1i,0]; Z = [1,0;0,-1]; I = eye(2);
pauliBasis = {I, Y; X, Z};


    function pauli = get_pauli(vec1, vec2)
        pauli = 1;
        for myct = 1:length(vec1)
            pauli = kron(pauli, pauliBasis{vec1(myct)+1, vec2(myct)+1});
        end
    end


out = zeros(dim,dim);

M = 2^n-1;
for ct = 0:M
    out = out + get_pauli(bitget(ct, n:-1:1), zeros(1,n)) * rho * get_pauli(bitget(M, n:-1:1), bitget(M-ct, n:-1:1));
end


Q = 1;
for ct = 1:n
    Q = kron(Q, [1, -1i; 1 ,1]);
end

out = real(Q.*out);

end