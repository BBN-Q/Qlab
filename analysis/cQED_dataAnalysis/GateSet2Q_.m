function [Uset] = GateSet2Q_(nbrPulses)
% Jay Gambetta, March 1st 2011
% 

p=0;
sm = destroy_(2);
sp = sm';
sx = sp+sm;
sy = +1i*sp-1i*sm;
sz = sparse([1 0;0 -1]);
si = speye(2);

Uin1{1}=speye(4);
Uin1{2}=expm(-1i*pi*kron(sx,si)/2);
Uin1{3}=expm(-1i*pi*kron(sx,si)/4);
Uin1{4}=expm(-1i*pi*kron(sy,si)/4);
Uin1{5}=expm(1i*pi*kron(sx,si)/4);
Uin1{6}=expm(1i*pi*kron(sy,si)/4);

Uin2{1}=speye(4);
Uin2{2}=expm(-1i*pi*kron(si,sx)/2);
Uin2{3}=expm(-1i*pi*kron(si,sx)/4);
Uin2{4}=expm(-1i*pi*kron(si,sy)/4);
Uin2{5}=expm(1i*pi*kron(si,sx)/4);
Uin2{6}=expm(1i*pi*kron(si,sy)/4);

for jindex = 1:nbrPulses
    for iindex = 1:nbrPulses
        p=p+1;
        Uset{p} =Uin2{jindex}*Uin1{iindex};
    end 
end

end