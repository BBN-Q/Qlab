function [beta, raw_paulis, C] = analyzeStateTomo(data, nbrQubits, nbrRepeats)
%analyzeStateTomo Wrapper function for state tomography.
%
% [beta, paulis, C] = analyzeStateTomo(data, nbrQubits, nbrRepeats)
%
% Expects calibration data then tomography data

calData = mean(reshape(data(1:nbrRepeats*2^nbrQubits), nbrRepeats, 2^nbrQubits), 1);
tomoData = mean(reshape(data(nbrRepeats*2^nbrQubits+1:end), nbrRepeats, 4^nbrQubits), 1);

[beta raw_paulis] = PauliTomo(calData, tomoData);
figure;
bar(raw_paulis)
PauliLabel();
title('Raw Inversion Pauli Decomposition');

rhoRaw = getRho(raw_paulis);
rhoWizard = WizardTomo_(rhoRaw, nbrQubits);
rhoPlot(rhoWizard);
purity = real(trace(rhoWizard^2))

pauliLabels = {'II', 'XI', 'YI', 'ZI', 'IX', 'IY', 'IZ', 'XY', 'XZ', 'YX', 'YZ', 'ZX', 'ZY', 'XX', 'YY', 'ZZ'};
[pauliOps, pauliStrs] = paulis(nbrQubits);

paulisWiz = zeros(16,1);
for ct = 1:length(pauliOps)
    pauliNum = find(strcmp(pauliLabels{ct}, pauliStrs));
    paulisWiz(ct) = real(trace(rhoWizard*pauliOps{pauliNum}));
end
figure;
bar(paulisWiz)
PauliLabel()
title('Constrained Tomography Pauli Decomposition','FontSize',14);
xlabel('Pauli Operator','FontSize',12);
ylabel('Overlap','FontSize',12);

C = Concurrence_(rhoWizard);
