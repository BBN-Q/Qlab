function [ rho ] = Psi2Rho_( psi )
% Jay Gambetta, March 1st 2011
% 
% Returns the state matrix rho = |psi><psi|
% Input 
%	psi = a column vector
% Return
%	rho = a state matrix 

 rho = psi * psi'; 
end

