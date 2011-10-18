function rhoPlot(paulis)

    rhoRaw = getRho(paulis);
    rhoWizard = WizardTomo_(rhoRaw, 2);
    
    figure
    subplot(1,2,1)
    bar3(real(rhoWizard));
    axis([0.5, 4.5, 0.5, 4.5, -1.2, 1.2]);
    title('Re[\rho]');
    
    subplot(1,2,2)
    bar3(imag(rhoWizard));
    axis([0.5, 4.5, 0.5, 4.5, -1.2, 1.2])
    title('Im[\rho]');

end