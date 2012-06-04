function [gateFidelity, choiSDP] = analyzeProcess(data, process, nbrQubits)

if ~exist('process', 'var')
    process = '1QId';
end
if ~exist('nbrQubits', 'var')
    nbrQubits = 1;
end

nbrAnalysisPulses = 12;
nbrPosPulses  = 12;
nbrRepeats = 1;

% seperate calibration experiments from tomography data, and reshape
% accordingly

%The data.abs_Data comes a matrix (numPulseSeqs X numExpsperPulseSeq) with
%the calibration data the last 2^nbrQubits of each row.  We need to go
%through each column and extract the calibration data and record a map of
%which measurement operator each experiment corresponds to.

numPreps = nbrAnalysisPulses^nbrQubits;
numMeas = nbrPosPulses^nbrQubits;

measMap = zeros(numMeas, numPreps, 'uint8');
measMat = zeros(numMeas, numPreps, 'double');
numSeqs = size(data,1);
expPerSeq = round((size(data,2)-2^nbrQubits*nbrRepeats)/nbrRepeats); 
measOps = cell(numSeqs,1);

idx=1;
for seqct = 1:size(data,1)
    cals = data(seqct,end-2^nbrQubits*nbrRepeats+1:end);
    raws = data(seqct,1:end-2^nbrQubits*nbrRepeats);
    measOps{seqct} = diag(mean(reshape(cals, nbrRepeats, 2^nbrQubits),1));
    measMat(idx:idx+expPerSeq-1) = mean(reshape(raws, nbrRepeats, expPerSeq),1);
    measMap(idx:idx+expPerSeq-1) = seqct;
    idx = idx+expPerSeq;
end

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
[chitheory, chicorrected, pauliMapTheory, pauliMapMLE, choiSDP] = SDP_QPT_(measMat, measOps, measMap, paulis,U_preps,U_meas,process,nbrQubits);
toc

% get choi matrices
choi_ideal = PauliMap2Choi_(pauliMapTheory, paulis, nbrQubits);
choi_mle = PauliMap2Choi_(pauliMapMLE, paulis, nbrQubits);
%choi_mle == choiSDP check this!

% compute metrics and plot
processFidelity = real(trace(chitheory*chicorrected))
gateFidelity = (2^nbrQubits*processFidelity+1)/(2^nbrQubits+1)

[evecs,~] = eig(choi_mle);
phase_fidelity = real(evecs(:,1)'*choi_ideal*evecs(:,1))


% create red-blue colorscale
cmap = [hot(50); 1-hot(50)];
cmap = cmap(19:19+63,:); % make a 64-entry colormap


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

% pauli_raw = MeasMat2PauliMap_(meas_matrix, measurementoperators, U_preps, U_meas, paulis, nbrQubits);
% choi_raw = PauliMap2Choi_(pauli_raw, paulis, nbrQubits);

% figure()
% imagesc(real(pauli_raw),[-1,1])
% colormap(cmap)
% colorbar
% 
% set(gca, 'XTick', 1:4^nbrQubits);
% set(gca, 'XTickLabel', paulistrings);
% 
% set(gca, 'YTick', 1:4^nbrQubits);
% set(gca, 'YTickLabel', paulistrings);
% xlabel('Input Pauli Operator');
% ylabel('Output Pauli Operator');
% title('Unconstrained Raw Map');

% how much did MLE change the process maps?
% dist2_mle_ideal = sqrt(abs(trace((choi_mle-choi_ideal)'*(choi_mle-choi_ideal))))/2
% dist2_mle_raw = sqrt(abs(trace((choi_mle-choi_raw)'*(choi_mle-choi_raw))))/2
% dist2_raw_ideal = sqrt(abs(trace((choi_ideal-choi_raw)'*(choi_ideal-choi_raw))))/2
% negativity_raw = real((sum(eig(choi_raw)) - sum(abs(eig(choi_raw))))/2)

end
