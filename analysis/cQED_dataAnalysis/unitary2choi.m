function  choi = unitary2choi(U)
%unitary2choi Returns the Choi super operator representation of a unitary.

d=size(U,1);
choi=zeros(d^2,d^2);
for ii=1:d
    for jj=1:d
        proj = zeros(d,d);
        proj(ii,jj) = 1;
        choi = choi + kron(proj,U*proj*U')/d;
    end
end


