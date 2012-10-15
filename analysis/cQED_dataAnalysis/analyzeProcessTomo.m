function [gateFidelity, choiSDP] = analyzeProcessTomo(data, idealProcess, nbrQubits, nbrPrepPulses, nbrReadoutPulses, nbrRepeats)
%analyzeProcess Performs SDP tomography, calculates gates fidelites and plots pauli maps.
%
% [gateFidelity, choiSDP] = analyzeProcessTomo(data, idealProcessStr, nbrQubits, nbrPrepPulses, nbrReadoutPulses, nbrRepeats) 

% seperate calibration experiments from tomography data, and reshape
% accordingly
%The data.abs_Data comes a matrix (numPulseSeqs X numExpsperPulseSeq) with
%the calibration data the last 2^nbrQubits of each row.  We need to go
%through each column and extract the calibration data and record a map of
%which measurement operator each experiment corresponds to.

numPreps = nbrReadoutPulses^nbrQubits;
numMeas = nbrPrepPulses^nbrQubits;

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


%Setup the state preparation and measurement pulse sets
U_preps = tomo_gate_set(nbrQubits, nbrReadoutPulses);
U_meas  = tomo_gate_set(nbrQubits, nbrPrepPulses);

%Call the SDP program to do the constrained optimization
[choiSDP, choiLSQ] = QPT_SDP(measMat, measOps, measMap, U_preps, U_meas, nbrQubits);

%Calculate the overlaps with the ideal gate
if ischar(idealProcess)
    unitaryIdeal = str2unitary(idealProcess);
else
    unitaryIdeal = idealProcess;
end
choiIdeal = unitary2choi(unitaryIdeal);

%Create the pauli operator strings
[~, pauliStrs] = paulis(nbrQubits);

%Convert to chi representation to compute fidelity metrics
chiExp = choi2chi(choiSDP);
chiIdeal = choi2chi(choiIdeal);

processFidelity = real(trace(chiExp*chiIdeal))
gateFidelity = (2^nbrQubits*processFidelity+1)/(2^nbrQubits+1)

%Create the pauli map for plotting
pauliMapIdeal = choi2pauliMap(choiIdeal);
pauliMapExp = choi2pauliMap(choiSDP);

%Create red-blue colorscale
cmap = [hot(50); 1-hot(50)];
cmap = cmap(19:19+63,:); % make a 64-entry colormap

figure()
imagesc(real(pauliMapExp),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', pauliStrs);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('MLE Reconstruction');

figure()
imagesc(real(pauliMapIdeal),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', pauliStrs);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('Ideal Map');


% how much did MLE change the idealProcessStr maps?
% dist2_mle_ideal = sqrt(abs(trace((choi_mle-choi_ideal)'*(choi_mle-choi_ideal))))/2
% dist2_mle_raw = sqrt(abs(trace((choi_mle-choi_raw)'*(choi_mle-choi_raw))))/2
% dist2_raw_ideal = sqrt(abs(trace((choi_ideal-choi_raw)'*(choi_ideal-choi_raw))))/2
% negativity_raw = real((sum(eig(choi_raw)) - sum(abs(eig(choi_raw))))/2)

end
