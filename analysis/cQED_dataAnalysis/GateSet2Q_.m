function Uset2Q = GateSet2Q_(nbrPulses)
% Jay Gambetta, March 1st 2011
% 

sm = full(destroy_(2));
sp = sm';
X = sp+sm;
Y = +1i*sp-1i*sm;
Z = [1 0;0 -1];
I = eye(2);


switch nbrPulses
    case 4
        %Four pulse set
        Uset{1}=speye(2);
        Uset{2}=expm(-1i*(pi/2)*X);
        Uset{3}=expm(-1i*(pi/4)*X);
        Uset{4}=expm(-1i*(pi/4)*Y);
    case 6
        %Six pulse set
        Uset{1}=speye(2);
        Uset{2}=expm(-1i*(pi/2)*X);
        Uset{3}=expm(-1i*(pi/4)*X);
        Uset{4}=expm(-1i*(pi/4)*Y);
        Uset{5}=expm(1i*(pi/4)*X);
        Uset{6}=expm(1i*(pi/4)*Y);
    case 12
        %12 pulse set
        Uset{1} = I;
        Uset{2} = expm(-1i*(pi/2)*X);
        Uset{3} = expm(-1i*(pi/2)*Y);
        Uset{4} = expm(-1i*(pi/2)*Z);
        Uset{5} = expm(-1i*(pi/3)*(1/sqrt(3))*(X+Y-Z));  %X+Y-Z 120
        Uset{6} = expm(-1i*(pi/3)*(1/sqrt(3))*(X-Y+Z));  %X-Y+Z 120
        Uset{7} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X+Y+Z));  %-X+Y+Z 120
        Uset{8} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X-Y-Z));  %X+Y+Z -120 (equivalent to -X-Y-Z 120)
        Uset{9} = expm(-1i*(pi/3)*(1/sqrt(3))*(X+Y+Z));  %X+Y+Z 120
        Uset{10} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X+Y-Z));  %X-Y+Z -120 (equivalent to -X+Y-Z 120)
        Uset{11} = expm(-1i*(pi/3)*(1/sqrt(3))*(X-Y-Z));  %-X+Y+Z -120 (equivalent to X-Y-Z 120
        Uset{12} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X-Y+Z));  %%X+Y-Z -120 (equivalent to -X-Y+Z 120
    otherwise
        error('Unable to handle number of pulses %d', nbrPulses);
end

p = 0;
Uset2Q = cell(nbrPulses^2,1);
for jindex = 1:nbrPulses
    for iindex = 1:nbrPulses
        p=p+1;
        Uset2Q{p} = kron(Uset{jindex},Uset{iindex});
    end 
end

end