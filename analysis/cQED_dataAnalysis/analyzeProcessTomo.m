function [gateFidelity, choiSDP, choiLSQ] = analyzeProcessTomo(data, idealProcess, nbrQubits, nbrPrepPulses, nbrReadoutPulses, nbrCalRepeats)
%analyzeProcess Performs SDP tomography, calculates gates fidelites and plots pauli maps.
%
% [gateFidelity, choiSDP] = analyzeProcessTomo(data, idealProcessStr, nbrQubits, nbrPrepPulses, nbrReadoutPulses, nbrRepeats) 

%seperate calibration experiments from tomography data and flatten the
%experiment data

%The data comes in as a matrix (numSeqs X numExpsPerSeq) with
%the calibration data the last nbrCalRepeats2^nbrQubits of each row. We need to go
%through each column and extract the calibration data and record a map of
%which measurement operator each experiment corresponds to.

%First cat multi-measurement data together
if iscell(data)
    numMeasChans = length(data);
    data = cat(1, data{:});
else
    numMeasChans = 1;
end

%Number of different preparations and readouts
numPreps = nbrPrepPulses^nbrQubits;
numMeas = nbrReadoutPulses^nbrQubits;
numExps = numPreps*numMeas*numMeasChans;
numCals = 2^(nbrQubits)*nbrCalRepeats;

%Rough rescaling by the variance to equalize things for the least squares 
approxScale = std(data(:,end-numCals+1:end), 0, 2);
data = bsxfun(@rdivide, data, approxScale);

%Pull out the raw experimental data
rawData = data(:, 1:numMeas);

%Pull out the calibration data as measurement operators and assign each exp. to a meas. operator 
measOps = cell(size(data,1),1);
measMap = nan(numExps,1);
results = nan(numExps,1);

%Go through row first as fast axis
idx = 1;
for row = 1:size(rawData,1)
    measOps{row} = diag(mean(reshape(data(row, end-numCals+1:end), nbrCalRepeats, 2^nbrQubits),1));
    for col = 1:size(rawData,2)
        results(idx) = rawData(row,col);
        measMap(idx) = row;
        idx = idx + 1;
    end
end

%Setup the state preparation and measurement pulse sets
U_preps = tomo_gate_set(nbrQubits, nbrPrepPulses);
U_meas  = tomo_gate_set(nbrQubits, nbrReadoutPulses);

%Call the SDP program to do the constrained optimization
[choiSDP, choiLSQ] = QPT_SDP(results, measOps, measMap, U_preps, U_meas, nbrQubits);

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

processFidelity_lsq = real(trace(choi2chi(choiLSQ)*chiIdeal))
gateFidelity_lsq = (2^nbrQubits*processFidelity_lsq+1)/(2^nbrQubits+1)

%Create the pauli map for plotting
pauliMapIdeal = choi2pauliMap(choiIdeal);
pauliMapLSQ = choi2pauliMap(choiLSQ);
pauliMapExp = choi2pauliMap(choiSDP);

%Permute according to hamming weight
weights = cellfun(@pauliHamming, pauliStrs);
[~, weightIdx] = sort(weights);

pauliMapIdeal = pauliMapIdeal(weightIdx, weightIdx);
pauliMapLSQ = pauliMapLSQ(weightIdx, weightIdx);
pauliMapExp = pauliMapExp(weightIdx, weightIdx);
pauliStrs = pauliStrs(weightIdx);

%Create red-blue colorscale
cmap = [hot(50); 1-hot(50)];
cmap = cmap(19:19+63,:); % make a 64-entry colormap

figure()
imagesc(real(pauliMapLSQ),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', pauliStrs);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('LSQ Reconstruction');

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
