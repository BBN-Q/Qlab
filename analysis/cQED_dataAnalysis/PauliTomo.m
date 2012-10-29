function [betas Pauli] = PauliTomo(calData, tomoData)

b = BetaExtract(calData);
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
 

Pauli = M\tomoData';
 
      