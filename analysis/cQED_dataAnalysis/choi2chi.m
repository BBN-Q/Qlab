function chi = choi2chi(choi)
%choi2chi Converts a Choi superoperator to a chi represtation in Pauli basis.

%Some dimensions
d2 = size(choi,1);
d = sqrt(d2);

%Get the Kraus operators from the eigen decomposition of the Choi
[vecs, vals] = eig(choi);
vals = diag(vals);

chi = zeros(d2,d2);

pauliOps = paulis(log2(d));

%Transform from the Krauss basis to the Pauli basis
for kraussct = 1:length(vals)
    tmpKrauss = reshape(vecs(:,kraussct), d,d)*sqrt(d); % Krauss operator should have norm of d
    for paulict1 = 1:d2
        pauliLeft = trace(pauliOps{paulict1}*tmpKrauss)/d;
        for paulict2 = 1:d2
            pauliRight = trace(pauliOps{paulict2}*tmpKrauss')/d;
            chi(paulict1, paulict2) = chi(paulict1, paulict2) +  vals(kraussct)*pauliLeft*pauliRight;
        end
    end
end

