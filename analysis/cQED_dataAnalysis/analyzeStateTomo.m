function [rhoLSQ, rhoSDP] = analyzeStateTomo(datastruct, nbrQubits, nbrPulses, nbrCalRepeats)
% analyzeStateTomo Wrapper function for state tomography.
%
% [rhoLSQ, rhoSDP, rhoWizard] = analyzeStateTomo(data, nbrQubits, nbrPulses, nbrCalRepeats)
%
% Expects tomography data then calibration data

%First separate out the data
data=datastruct.data;
numMeas = length(data);
measOps = cell(numMeas,1);
tomoData = [];
varData = [];

for ct = 1:numMeas
    data{ct} = real(data{ct});
    %Average over calibration repeats
    calData = mean(reshape(data{ct}(end-nbrCalRepeats*(2^nbrQubits)+1:end), nbrCalRepeats, 2^nbrQubits), 1);

    %Pull out the calibrations as diagonal measurement operators
    measOps{ct} = diag(calData);

    %The data to invert
    tomoData = [tomoData; data{ct}(1:end-nbrCalRepeats*(2^nbrQubits))];
    
    %variance
    varData = [varData; datastruct.realvar{ct}(1:end-nbrCalRepeats*(2^nbrQubits))];
        
end
%Map each experiment to the appropriate readout pulse 
measOpMap = reshape(repmat(1:numMeas, nbrPulses^nbrQubits, 1), numMeas*(nbrPulses^nbrQubits), 1); 
measPulseMap = repmat([1:nbrPulses^nbrQubits]', numMeas, 1);

%Use a helper to get the measurement unitaries.
measPulseUs = tomo_gate_set(nbrQubits, nbrPulses);

%TODO: handle variances
varMat = diag(varData);

%Now call the inversion routines

%First least squares
rhoLSQ = QST_LSQ(tomoData, varMat, measPulseMap, measOpMap, measPulseUs, measOps, nbrQubits);

pauliSetPlot(rho2pauli(rhoLSQ));
title('LSQ Inversion Pauli Decomposition');

%Now constrained SDP
rhoSDP = QST_SDP_uncorrelated(tomoData, varMat, measPulseMap, measOpMap, measPulseUs, measOps, nbrQubits);

pauliSetPlot(rho2pauli(rhoSDP));
title('SDP Inversion Pauli Decomposition');


% rhoRaw = getRho(raw_paulis);
% rhoWizard = WizardTomo_(rhoLSQ, nbrQubits);
% pauliSetPlot(rho2pauli(rhoWizard));
% title('Wizard Pauli Decomposition');
% 
% C = Concurrence_(rhoWizard);

end
