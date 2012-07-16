function b = BetaExtract(calData)

% assumes id, pi on Q1, pi on Q2, pipi
A = [1 1 1 1; 1 -1 1 -1; 1 1 -1 -1;1 -1 -1 1];

b = A\calData';

