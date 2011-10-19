function [beta, paulis, C] = analyzeTomo(data)
    [beta paulis] = PauliTomo(data);
    figure;
    bar(paulis)
    PauliLabel();
    
    rhoRaw = getRho(paulis);
    rhoWizard = WizardTomo_(rhoRaw, 2);
    rhoPlot(rhoWizard);
    
    C = Concurrence_(rhoWizard);
end