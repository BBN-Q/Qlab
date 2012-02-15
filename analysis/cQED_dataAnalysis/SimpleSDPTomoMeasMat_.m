function choi_SDP2 = SimpleSDPTomoMeasMat_(measmat,measurementoperators,U_preps,U_meas, pauliopts, numberofqubits,verbose)
% Jay Gambetta and Seth Merkel, Jan 20th 2012
% Simplified by Colm Ryan and Blake Johnson, Feb 15th, 2012
% 
% this function perfomrs semi definte programing to find the closes physical map in the choi represenation to the data. It uses yalmip and sudumi
% Input
%	measmat = the measurement mat of the measurement opterators
%   measurementopts= the set of measurement opts for each calibrations 
%   U_preps = the set of preperation unitaries 
%   U_meas = the set of measurement unitaries 
%   pauliopts = a cell of all the pauli operators
%   numberofqubits = the number of qubits
% Return
%	choi_SDP2 = the corrected physical state
if nargin < 7
    verbose =0;
end

yalmip('clear')
d = 2^numberofqubits;
d2 = 4^numberofqubits;

numberofmeasurements = size(measmat,1);
numberofpreps = size(measmat,2);

% different prepartions
psiin = zeros(d,1);
psiin(1,1) = 1; % assume perfect preparation in the ground state
rhoin = psiin * psiin'; % convert to density matrix

% transform the measurement operator by the measurement pulse
for jj=1:length(U_preps) 
    for kk = 1:length(U_meas)
        measurementoptsset{jj}{kk}= U_meas{kk}'*measurementoperators{jj}*U_meas{kk};
    end
end

% transform the initial state by the preparation pulse
for jj = 1:length(U_preps)
    rho_preps{jj} = U_preps{jj}*rhoin*U_preps{jj}';
end

choiSDP = sdpvar(d2,d2,'full','complex');
predMat = sdpvar(d2,d2,'full','real');

for prepct = 1:numberofpreps
    for measct = 1:numberofmeasurements
        predMat(prepct, measct) = trace(choiSDP*kron(rho_preps{prepct}.', measurementoptsset{prepct}{measct}))*d;
    end
end

constraints = choiSDP>0;

solvesdp(constraints,norm(predMat - measmat),sdpsettings('verbose',verbose));

choi_SDP2 = double(choiSDP);


end
