function b = BetaExtract(stomodat)

id = sum(stomodat(1:4))/4; %II
pi1 = sum(stomodat(5:8))/4; %ZI
pi2 = sum(stomodat(9:12))/4; %IZ
pipi = sum(stomodat(13:16))/4; %ZZ

m = [id; pi1; pi2; pipi];
A = [1 1 1 1; 1 -1 1 -1; 1 1 -1 -1;1 -1 -1 1];

b = A\m;

