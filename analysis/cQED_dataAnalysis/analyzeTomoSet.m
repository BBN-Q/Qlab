function concurrence = analyzeTomoSet(data)

concurrence = zeros(size(data.abs_Data,1),1);
for ct = 1:length(concurrence)
    % extract cals and data
    nbrRepeats = 2;
    nbrQubits = 2;
    thisSlice = data.abs_Data(ct, :);
    calData = mean(reshape(thisSlice(1:nbrRepeats*2^nbrQubits), nbrRepeats, 2^nbrQubits), 1);
    tomoData = mean(reshape(thisSlice(nbrRepeats*2^nbrQubits+1:end), nbrRepeats, 4^nbrQubits), 1);

    [~, raw_paulis] = PauliTomo(calData, tomoData);
    rhoRaw = getRho(raw_paulis);
    rhoWizard = WizardTomo_(rhoRaw, nbrQubits);
    fprintf('Purity ct %d: %f\n', ct, trace(rhoWizard^2));
    concurrence(ct) = Concurrence_(rhoWizard);
end