function [betas Pauli] = PauliTomo(stomodat)

b = BetaExtract(stomodat)
% b0 II +b1 ZI + b2 IZ + b3 ZZ
b0 = b(1);
b1 = b(2);
b2 = b(3);
b3 = b(4);
betas = b;
%    II   XI YI  ZI  IX  IY  IZ  XY  XZ  YX  YZ  ZX  ZY  XX  YY  ZZ   Q1 Q2    
M = [b0   0  0   b1  0   0   b2  0   0   0   0   0   0   0   0   b3; %Id Id
     b0   0  0   b1  0   0  -b2  0   0   0   0   0   0   0   0  -b3; %Id Xp
     b0   0  0   b1  0   b2  0   0   0   0   0   0   b3  0   0   0;  %Id X90p
     b0   0  0   b1 -b2  0   0   0   0   0   0  -b3  0   0   0   0;  %Id Y90p
     b0   0  0  -b1  0   0   b2  0   0   0   0   0   0   0   0  -b3; %Xp Id
     b0   0  0  -b1  0   0  -b2  0   0   0   0   0   0   0   0   b3; %Xp Xp
     b0   0  0  -b1  0   b2  0   0   0   0   0   0  -b3  0   0   0;  %Xp X90p
     b0   0  0  -b1 -b2  0   0   0   0   0   0   b3  0   0   0   0;  %Xp Y90p
     b0   0  b1  0   0   0   b2  0   0   0   b3  0   0   0   0   0 ; %X90p Id
     b0   0  b1  0   0   0  -b2  0   0   0  -b3  0   0   0   0   0 ; %X90p Xp
     b0   0  b1  0   0   b2  0   0   0   0   0   0   0   0   b3  0;  %X90p X90p
     b0   0  b1  0  -b2  0   0   0   0  -b3  0   0   0   0   0   0;  %X90p Y90p
     b0  -b1 0   0   0   0   b2  0  -b3  0   0   0   0   0   0   0;  %Y90p Id
     b0  -b1 0   0   0   0  -b2  0   b3  0   0   0   0   0   0   0;  %Y90p Xp
     b0  -b1 0   0   0   b2  0  -b3  0   0   0   0   0   0   0   0;  %Y90p X90p
     b0  -b1 0   0  -b2  0   0   0   0   0   0   0   0   b3  0   0   %Y90p Y90p
     ];
 
 
 
 %IdVal = (stomodat(1)+stomodat(2)+stomodat(3)+stomodat(4)+stomodat(84)+stomodat(84)+stomodat(83)+stomodat(82))/8;
fullmeas = stomodat(17:80);%-IdVal;
 for m=1:16
     measvec(m)=0;
     for n = 1:4
        % if (n == 2 || 3)
            measvec(m)= measvec(m)+ fullmeas((m-1)*4+n);
        % end
     end
     measvec(m) = measvec(m)/4;
 end
 
 %measvec(11)=(stomodat(19)+stomodat(25))/2;
 %measvec(12)=(stomodat(20)+stomodat(26))/2;
 %measvec(15)=(stomodat(23)+stomodat(27))/2;
 %measvec(16)=(stomodat(24)+stomodat(28))/2;

 Pauli = M\measvec';
 
      