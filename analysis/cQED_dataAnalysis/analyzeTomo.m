function [beta, paulis, C] = analyzeTomo(data, nbrRepeats)

    %Analyze two qubit state tomography
    %Expects calibration data then tomography data
    
    calData = mean(reshape(data(1:4*nbrRepeats), nbrRepeats, 4), 1);
    tomoData = mean(reshape(data(4*nbrRepeats+1:end), nbrRepeats, 16), 1);

    [beta paulis] = PauliTomo(calData, tomoData);
    figure;
    bar(paulis)
    PauliLabel();
    title('Raw Inversion Pauli Decomposition');
    
    rhoRaw = getRho(paulis);
    rhoWizard = WizardTomo_(rhoRaw, 2);
    rhoPlot(rhoWizard);
    
    
    pauliStruct = PauliOperators_(2);
    pauliLabels = {'II', 'XI', 'YI', 'ZI', 'IX', 'IY', 'IZ', 'XY', 'XZ', 'YX', 'YZ', 'ZX', 'ZY', 'XX', 'YY', 'ZZ'};
    pauliOps = pauliStruct.opt;

    paulisWiz = zeros(16,1);
    for ct = 1:length(pauliOps)
        pauliNum = find(strcmp(pauliLabels{ct}, pauliStruct.string));
        paulisWiz(ct) = real(trace(rhoWizard*pauliOps{pauliNum}));
    end
    figure;
    bar(paulisWiz)
    PauliLabel()
    title('Constrained Tomography Pauli Decomposition','FontSize',14);
    xlabel('Pauli Operator','FontSize',12);
    ylabel('Overlap','FontSize',12);
    
    C = Concurrence_(rhoWizard);
end