function [Uset] = GateSet1Q_(nbrPulses)
% Blake Johnson, Feb 10, 2012
 
sm = destroy_(2);
sp = sm';
sx = sp+sm;
sy = +1i*sp-1i*sm;
sz = sparse([1 0;0 -1]);
si = speye(2);

Uset{1}=speye(2);
Uset{2}=expm(-1i*pi*sx/2);
Uset{3}=expm(-1i*pi*sx/4);
Uset{4}=expm(-1i*pi*sy/4);
Uset{5}=expm(1i*pi*sx/4);
Uset{6}=expm(1i*pi*sy/4);

end