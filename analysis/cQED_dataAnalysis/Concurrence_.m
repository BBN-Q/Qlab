function [con,ef] = Concurrence_(rho)

% Authors Jay Gambetta
% Feb 28th 2011
%
% Calculates the concurrence of a state rho

sp = destroy_(2);
sm = sp';
sy = -i*sp+i*sm;

A = rho*kron(sy,sy)*conj(rho)*kron(sy,sy);
lambda = sort(sqrt(eig(A)),'descend');
% so i should try to think about if i want to add to check that rho is positive
con = max(0,real(lambda(1) - lambda(2)-lambda(3) -lambda(4)));
ef = -0.5*(1+sqrt(1-con^2))*log2(0.5*(1+sqrt(1-con^2)))-(1-0.5*(1+sqrt(1-con^2)))*log2(1-0.5*(1+sqrt(1-con^2)));
