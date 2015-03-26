function concurrence = analyzeTomoSet(data)

concurrence = zeros(size(data.abs_Data,1),1);

pauliLabels = {'II', 'XI', 'YI', 'ZI', 'IX', 'IY', 'IZ', 'XY', 'XZ', 'YX', 'YZ', 'ZX', 'ZY', 'XX', 'YY', 'ZZ'};
nbrRepeats = 2;
nbrQubits = 2;
[pauliOps, pauliStrs] = paulis(nbrQubits);

paulisWiz = zeros(length(concurrence),16);
for ct = 1:length(concurrence)
    % extract cals and data
    thisSlice = data.abs_Data(ct, :);
    tomoData = mean(reshape(thisSlice(1:end-nbrRepeats*2^nbrQubits), nbrRepeats, 4^nbrQubits), 1);
    calData = mean(reshape(thisSlice(end-nbrRepeats*2^nbrQubits+1:end), nbrRepeats, 2^nbrQubits), 1);

    [~, raw_paulis] = PauliTomo(calData, tomoData);
    rhoRaw = getRho(raw_paulis);
    rhoWizard = WizardTomo_(rhoRaw, nbrQubits);
    for paulict = 1:length(pauliOps)
        pauliNum = find(strcmp(pauliLabels{paulict}, pauliStrs));
        paulisWiz(ct,paulict) = real(trace(rhoWizard*pauliOps{pauliNum}));
    end
    fprintf('Purity ct %d: %f\n', ct, trace(rhoWizard^2));
    concurrence(ct) = Concurrence_(rhoWizard);
end

figure()
plot(0:pi/64:pi, paulisWiz + repmat(0:2:30, 65, 1));
set(gca(), 'YTick', 0:2:30);
set(gca(), 'YTickLabel', pauliLabels);
ylim([-1, 31]);
xlim([0,pi]);
set(gca(), 'YGrid', 'On');
xlabel('CR Gate Angle (rad.)');



