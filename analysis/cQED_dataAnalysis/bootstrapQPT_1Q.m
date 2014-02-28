%Loop over repeated calls to analyzeProcess to bootstrap and estimate of
%the uncertainty of the gate fidelity. 

%If we have repeated the experiment then we can use the difference between
%experiments as an estimate for the noise.  Here we assume the 6 pulse gate
%set

nbrRepeats = 2;
nbrGates = 6;
nbrCals = 2;

numSims = 1000;

shouldBeZeros = mean(diff(reshape(data.abs_Data,nbrRepeats,nbrGates^2+nbrCals),1,1),1);

noiseSD = std(shouldBeZeros);

idealGate = '1QY90p';

%Now use this to generate new simulated experiments and run the tomography
gateFidelities = zeros([numSims, 1]);

for simct = 1:numSims
    simData = noiseSD*randn(size(data.abs_Data)) + data.abs_Data;
    
    gateFidelities(simct) = analyzeProcess(simData, idealGate, 1);
end

%To get the confidence interval we find the two points which capture the
% ci% of the data

ci = 0.95;
alpha = 1-ci;
ciLowIdx = round(numSims*0.5*alpha);
ciHighIdx = round(numSims*1-0.5*alpha);
tmpSorted = sort(gateFidelities);

ciLow = tmpSorted(ciLowIdx);
ciHigh = tmpSorted(ciHighIdx);

%Report the final number 
goodFidelity = analyzeProcess(data.abs_Data, idealGate, 1);

fprintf('MLE Gate Fidelity of %.3f with a CI of (%.3f, %.3f) or -%.3f + %.3f\n', goodFidelity, ciLow, ciHigh, goodFidelity-ciLow, ciHigh-goodFidelity)



