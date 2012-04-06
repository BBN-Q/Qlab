function analyzeProcess(data, process, nbrQubits)

if ~exist('process', 'var')
    process = '1QId';
end
if ~exist('nbrQubits', 'var')
    nbrQubits = 1;
end

nbrAnalysisPulses = 6;
nbrPosPulses  = 6;
nbrRepeats = 2;

% seperate calibration experiments from tomography data, and reshape
% accordingly
Cals = data.abs_Data(end-2*nbrRepeats+1:end);
Raws = data.abs_Data(1:end-2*nbrRepeats);

numberofpreps = nbrAnalysisPulses^nbrQubits;
numberofmeasurements = nbrPosPulses^nbrQubits;

measurementoperators = {diag(mean(reshape(Cals, nbrRepeats, 2^nbrQubits)))};
measurementoperators = repmat(measurementoperators, 1, numberofpreps);
mvecs = mean(reshape(Raws, nbrRepeats, numberofpreps*numberofmeasurements));
meas_matrix = reshape(mvecs, numberofmeasurements, numberofpreps);

% setup SDP problem
tmp = PauliOperators_(nbrQubits);
paulis = tmp.opt;
paulistrings = tmp.string;

switch nbrQubits
    case 1
        [U_preps] = GateSet1Q_(nbrAnalysisPulses);
        [U_meas]  = GateSet1Q_(nbrPosPulses);
    case 2
        [U_preps] = GateSet2Q_(nbrAnalysisPulses);
        [U_meas]  = GateSet2Q_(nbrPosPulses);
end
 
tic
[chitheory, chicorrected, pauliMapTheory, pauliMapMLE, choiSDP] = SDP_QPT_(meas_matrix,measurementoperators,paulis,U_preps,U_meas,process,nbrQubits);
toc

% get choi matrices
choi_ideal = PauliMap2Choi_(pauliMapTheory, paulis, nbrQubits);
choi_mle = PauliMap2Choi_(pauliMapMLE, paulis, nbrQubits);
%choi_mle == choiSDP check this!

% compute metrics and plot
processFidelity = trace(chitheory*chicorrected)
gateFidelity = (2^nbrQubits*processFidelity+1)/(2^nbrQubits+1)

[evecs,~] = eig(choi_mle);
phase_fidelity = real(evecs(:,1)'*choi_ideal*evecs(:,1))


% create red-blue colorscale
%num = 200;
%cmap = [hot(num); 1-hot(num)];
%cmap = cmap(70:end-70,:);
cmap = [hot(50); 1-hot(50)];
cmap = cmap(18:18+63,:); % make a 64-entry colormap


figure()
imagesc(real(pauliMapMLE),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', paulistrings);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', paulistrings);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('MLE Reconstruction');

figure()
imagesc(real(pauliMapTheory),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', paulistrings);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', paulistrings);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('Ideal Map');
% also look at the data without MLE

pauli_raw = MeasMat2PauliMap_(meas_matrix, measurementoperators, U_preps, U_meas, paulis, nbrQubits);
choi_raw = PauliMap2Choi_(pauli_raw, paulis, nbrQubits);

figure()
imagesc(real(pauli_raw),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', paulistrings);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', paulistrings);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('Unconstrained Raw Map');
% how much did MLE change the process maps?
dist2_mle_ideal = sqrt(abs(trace((choi_mle-choi_ideal)'*(choi_mle-choi_ideal))))/2
dist2_mle_raw = sqrt(abs(trace((choi_mle-choi_raw)'*(choi_mle-choi_raw))))/2
dist2_raw_ideal = sqrt(abs(trace((choi_ideal-choi_raw)'*(choi_ideal-choi_raw))))/2
negativity_raw = real((sum(eig(choi_raw)) - sum(abs(eig(choi_raw))))/2)

end
