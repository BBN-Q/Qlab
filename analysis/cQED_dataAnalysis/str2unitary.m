function Uout = str2unitary(strIn)
%str2unitary Converts a string description of a gate into a unitary matrix.

%Basic Pauli operators
X = [0,1; 1,0];
Y = [0,-1i,1i,0];
Z = [1 0;0 -1];
I = eye(2);

switch strIn
    case 'CNOT12'
        Uout =  [1,0,0,0;0,1,0,0;0,0,0,1;0,0,1,0];
    case 'InvCNOT12'
        Uout =  [0,1,0,0;1,0,0,0;0,0,1,0;0,0,0,1];
    case '1QId'
        Uout = speye(2);
    case '1QX90p'
        Uout = expm(-1i*pi*X/4);
    case '1QX90m'
        Uout = expm(1i*pi*X/4);
    case '1QY90p'
        Uout = expm(-1i*pi*Y/4);
    case '1QY90m'
        Uout = expm(1i*pi*Y/4);
    case '1QXp'
        Uout = expm(-1i*pi*X/2);
    case '1QYp'
        Uout = expm(-1i*pi*Y/2);
    case '1QX45p'
        Uout = expm(-1i*pi*X/8);
    case '1QX22p'
        Uout = expm(-1i*pi*X/16);
    case '1QHad'
        Uout = expm(-1i*(pi/2)*(1/sqrt(2))*(X+Z));
    case '1QZ90'
        Uout = expm(-1i*(pi/4)*Z);
    case '1QT'
        Uout = expm(-1i*(pi/8)*Z);
    case 'Id'
        Uout = eye(4);
    case 'XI'
        Uout = expm(-1i*kron(X,I)*pi/2);
    case 'IX'
        Uout = expm(-1i*kron(I,X)*pi/2);
    case 'YI'
        Uout = expm(-1i*kron(Y,I)*pi/2);
    case 'IY'
        Uout = expm(-1i*kron(I,Y)*pi/2);
    case 'X_2I'
        Uout = expm(-1i*kron(X,I)*pi/4);
    case 'IX_2'
        Uout = expm(-1i*kron(I,X)*pi/4);
    case 'Y_2I'
        Uout = expm(-1i*kron(Y,I)*pi/4);
    case 'IY_2'
        Uout = expm(-1i*kron(I,Y)*pi/4);
    case 'X_8I'
        Uout = expm(-1i*kron(X,I)*pi/16);
    case 'X_4I'
        Uout = expm(-1i*kron(X,I)*pi/8);
    case 'IX_8'
        Uout = expm(-1i*kron(I,X)*pi/16);
    case 'IX_4'
        Uout = expm(-1i*kron(I,X)*pi/8);
    otherwise
        error('Unrecognized gate');
end
