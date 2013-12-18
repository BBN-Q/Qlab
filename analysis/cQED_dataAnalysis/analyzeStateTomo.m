function [beta, raw_paulis, C] = analyzeStateTomo(data, nbrQubits, nbrPulses, nbrCalRepeats)
% analyzeStateTomo Wrapper function for state tomography.
%
% [rhoLSQ, rhoSDP, rhoWizard] = analyzeStateTomo(data, nbrQubits, nbrPulses, nbrCalRepeats)
%
% Expects tomography data then calibration data

%First separate out the data

%Average over calibration repeats
calData = mean(reshape(data(end-nbrCalRepeats*(2^nbrQubits)+1:end), nbrCalRepeats, 2^nbrQubits), 1);

%Pull out the calibrations as diagonal measurement operators
measOps = cell(1,1);
measOps{1} = diag(calData);

%The data to invert
tomoData = data(1:end-nbrCalRepeats*(2^nbrQubits));

%Map each experiment to the appropriate readout pulse 
measPulseMap = 1:nbrPulses^nbrQubits;
measOpMap = ones(36,1);

%Use a helper to get the measurement unitaries.
measPulseUs = tomo_gate_set(nbrQubits, nbrPulses);

%TODO: handle variances
varMat = diag(ones(nbrPulses^nbrQubits,1));

%Now call the inversion routines

%First least squares
rhoLSQ = QST_LSQ(tomoData, varMat, measPulseMap, measOpMap, measPulseUs, measOps, nbrQubits);

function pauli_label()
    [~, pauliStrs] = paulis(nbrQubits);
    set(gca(), 'XTick', 1:4^nbrQubits); 
    set(gca(), 'XTickLabel', pauliStrs);
end

figure()
subplot(2,1,1)
bar(rho2pauli(rhoLSQ));
pauli_label();
title('LSQ Inversion Pauli Decomposition');


%Now constrained SDP
rhoSDP = QST_SDP_uncorrelated(tomoData, varMat, measPulseMap, measOpMap, measPulseUs, measOps, nbrQubits);

subplot(2,1,2)
bar(rho2pauli(rhoSDP));
pauli_label();
title('SDP Inversion Pauli Decomposition');


% rhoRaw = getRho(raw_paulis);
% rhoWizard = WizardTomo_(rhoRaw, nbrQubits);
% rhoPlot(rhoWizard);
% purity = real(trace(rhoWizard^2))
% 
% pauliLabels = {'II', 'XI', 'YI', 'ZI', 'IX', 'IY', 'IZ', 'XY', 'XZ', 'YX', 'YZ', 'ZX', 'ZY', 'XX', 'YY', 'ZZ'};
% [pauliOps, pauliStrs] = paulis(nbrQubits);
% 
% paulisWiz = zeros(16,1);
% for ct = 1:length(pauliOps)
%     pauliNum = find(strcmp(pauliLabels{ct}, pauliStrs));
%     paulisWiz(ct) = real(trace(rhoWizard*pauliOps{pauliNum}));
% end
% figure;
% bar(paulisWiz)
% PauliLabel()
% title('Constrained Tomography Pauli Decomposition','FontSize',14);
% xlabel('Pauli Operator','FontSize',12);
% ylabel('Overlap','FontSize',12);
% 
% C = Concurrence_(rhoWizard);

end
