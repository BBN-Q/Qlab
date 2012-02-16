function choi_SDP2 = SimpleSDPTomoMeasMat_(measmat, measurementoperators, U_preps, U_meas, nbrQubits, verbose)
% Jay Gambetta and Seth Merkel, Jan 20th 2012
% Considerably simplified by Colm Ryan and Blake Johnson, Feb 15th, 2012
% 
% this function perfomrs semi definte programing to find the closest physical map in the choi represenation to the data. It uses yalmip and sudumi
% Input
%	measmat = the measurement mat of the measurement results (numPrep x
%	numMeas)
%   measurementopts= measurement operator for each calibration. e.g. measuring 1V for the ground state and 1.23V for the excited state gives [[1, 0],[0,1.23]] 
%   U_preps = cell array of the preperation unitaries 
%   U_meas = cell array of read-out unitaries 
%   nbrQubits = the number of qubits
%   verbose - pass through boolean to the yalmip
% Return
%	choi_SDP2 = the constrained physical process Choi matrix

%Default to quiet
if nargin < 7
    verbose =0;
end

%Clear the yalmip (why?)
yalmip('clear')

%Some dimensions
d = 2^nbrQubits;
d2 = 4^nbrQubits;
d4 = 16^nbrQubits;

numMeas = length(U_preps);
numPrep = length(U_meas);

% assume perfect preparation in the ground state
rhoin = zeros(d,d);
rhoin(1,1) = 1;

% transform the initial state by the preparation pulse
rho_preps = cell(numPrep,1);
for jj = 1:length(U_preps)
    rho_preps{jj} = U_preps{jj}*rhoin*U_preps{jj}';
end

% transform the measurement operator by the measurement pulse
measurementoptsset = cell(numMeas,1);
for jj=1:length(U_preps) 
    for kk = 1:length(U_meas)
        measurementoptsset{jj}{kk}= U_meas{kk}'*measurementoperators{jj}*U_meas{kk};
    end
end

%Set up the SDP problem with Yalmip
%First the Choi matrix in square form
choiSDP = sdpvar(d2, d2, 'hermitian', 'complex');

%Now each measurement result corresponds to a linear combination of Choi
%matrix (S) elements: for a given rhoin and measOp then measResult = Tr(S*kron(rhoin.', measOp))
%Thus we can write down the result from the tomography experiment with all combintations of inputs
%and measurements as d4xd4 matrix A: A*vec(choiSDP) = fitResults
%Using the trick that trace(C*D) = sum(C.'.*D) = sum(D.' * C)
%Then each row of A is the row-stacked version of kron(rhoin.' , measOp) 
%Or the col-stacked version of kron(rhoin, measOp.')
A = zeros(numPrep*numMeas,d4);
for prepct = 1:numPrep
    for measct = 1:numMeas
        %Have to multiply by d to match Jay's convection of dividing the
        %Choi matrix by d
        tmpMat = kron(rho_preps{prepct}, measurementoptsset{prepct}{measct}.')*d;
        A(prepct + (measct-1)*numPrep, :) = tmpMat(:);
    end
end

%Constrain the Choi matrix to be positive semi-definite
constraint = choiSDP>=0;

%Call the solver
solvesdp(constraint,norm(A*choiSDP(:) - measmat(:), 2),sdpsettings('verbose',verbose));

%Extract the matrix values from the result
choi_SDP2 = double(choiSDP);

end
