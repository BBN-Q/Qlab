function [ pauli1 ] = PauliOperators_( numberofqubits )
% Jay Gambetta, March 1st 2011
% 
% This function returns a set of pauli operators for n qubits
% Input 
%	numberofqubits = number of qubits
%Output 
%   the paulioperaters
% i really want to change this so that it does not do it in operator form
% by in string
sp = destroy_(2);
sm = sp';

sx = sp+sm;
sy = -1i*sp+1i*sm;
sz = sparse([1 0;0 -1]);
si = speye(2);

for kindex = 1:4^numberofqubits
    Xtemp = 1;
    for jindex=1:numberofqubits
        % convert each integer into a unit number with entries 0, 1, 2, 3
        element = mod(floor(kindex/(4^(jindex-1))),4); 
        if element == 0
            cof = 'I';
            ope = si;
        elseif element ==1
            cof = 'X';
            ope = sx;
        elseif element ==2
            cof = 'Y';
            ope = sy;
        else
            cof = 'Z';
            ope = sz;
        end
        blah.stringpauli(numberofqubits+1-jindex) = cof;
        Xtemp = kron(ope,Xtemp);
    end
     pauli1.string{kindex} =blah.stringpauli;
     pauli1.opt{kindex} = Xtemp;
end 
 



