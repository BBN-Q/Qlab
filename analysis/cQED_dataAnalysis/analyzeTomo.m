function [beta, paulis, C] = analyzeTomo(data, nbrRepeats)

    %Analyze two qubit state tomography
    %Expects calibration data then tomography data
    
    calData = mean(reshape(data(1:4*nbrRepeats), nbrRepeats, 4), 1);
    tomoData = mean(reshape(data(4*nbrRepeats+1:end), nbrRepeats, 16), 1);

    [beta paulis] = PauliTomo(calData, tomoData);
    figure;
    bar(paulis)
    PauliLabel();
    
    rhoRaw = getRho(paulis);
    rhoWizard = WizardTomo_(rhoRaw, 2);
    rhoPlot(rhoWizard);
    
    C = Concurrence_(rhoWizard);
end