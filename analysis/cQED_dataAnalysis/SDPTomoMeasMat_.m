function choi_SDP2 = SDPTomoMeasMat_(measmat,measurementoperators,U_preps,U_meas, pauliopts, numberofqubits,verbose)
% Jay Gambetta and Seth Merkel, Jan 20th 2012
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
d4 = 16^numberofqubits;

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

ExpDecomposition = zeros(numberofmeasurements*numberofpreps,d2*d2);

for ii =1:d2
    for ll=1:numberofpreps
        pauliExpectationOfRhoIn = trace(rho_preps{ll}.'*pauliopts{ii});
        for jj=1:d2
            for mm=1:numberofmeasurements
                pauliDecompOfMeasOp = trace(pauliopts{jj}*measurementoptsset{ll}{mm});
                ExpDecomposition((mm-1)*numberofpreps+ll,(jj-1)*(d2)+ii) = -real(pauliExpectationOfRhoIn*pauliDecompOfMeasOp/d);
            end
        end
    end
end

measvec = measmat(:); % get a vector of the measurement results
meas_trace = measvec.'*measvec;

choivec = sdpvar(d4,1,'full','real'); % a vectorized Pauli decomposition of the Choi matrix
t = sdpvar(1,1,'full','real'); % slack variable

% the pauli decomposition of the state (not the confusing ordering as the
% identity is last)
choi_SDP = zeros(d2);

for ii =1:d2
    for jj=1:d2
        choi_SDP = choi_SDP + choivec((jj-1)*(d2)+ii)*kron(pauliopts{ii},pauliopts{jj})/d2;
    end
end

% The Z Matrix
Z = zeros(d2*d2+1,d2*d2+1);
temp = zeros(d2*d2+1,d2*d2+1);
temp(1,1) = 1;
Z = Z + t*temp;

newvariable = sqrtm(ExpDecomposition.'*ExpDecomposition);

Z(2:end,1) = newvariable*choivec;
Z(1,2:end) = choivec.'*newvariable.';
Z(2:end,2:end) = eye(d2*d2); % assume no correlated errors and uniform variances

constraints = [Z>0, choi_SDP>0];

obj =  meas_trace + measvec.'*ExpDecomposition*choivec + choivec.'*ExpDecomposition.'*measvec + t;

solvesdp(set(constraints),obj,sdpsettings('verbose',verbose));

xvecd = double(choivec);

% unpack result into a choi matrix
choi_SDP2 = zeros(d2);
for ii =1:d2
    for jj=1:d2
        choi_SDP2 = choi_SDP2 + xvecd((jj-1)*(d2)+ii)*kron(pauliopts{ii},pauliopts{jj})/d2;
    end
end


end
