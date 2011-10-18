function rho2 = getRho(Pauli)

    sp = destroy_(2);
    sm = sp';
    sx = sp+sm;
    sy = -i*sp+i*sm;
    sz = sparse([1 0;0 -1]);
    si = speye(2);

    n=2;
    pauliopts{1}=kron(si,si);
    pauliopts{2}=kron(sx,si);
    pauliopts{3}=kron(sy,si);
    pauliopts{4}=kron(sz,si);

    pauliopts{5}=kron(si,sx);
    pauliopts{6}=kron(si,sy);
    pauliopts{7}=kron(si,sz);

    pauliopts{8}=kron(sx,sy);
    pauliopts{9}=kron(sx,sz);
    pauliopts{10}=kron(sy,sx);
    pauliopts{11}=kron(sy,sz);
    pauliopts{12}=kron(sz,sx);
    pauliopts{13}=kron(sz,sy);
    pauliopts{14}=kron(sx,sx);
    pauliopts{15}=kron(sy,sy);
    pauliopts{16}=kron(sz,sz);
    %rho=kron(sparse([1 0;0 0]),sparse([1 0;0 0]));
    coefs=Pauli;
    rho2=Pauli2Rho_(coefs,pauliopts,2);