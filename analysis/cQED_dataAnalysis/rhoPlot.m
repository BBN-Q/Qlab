function rhoPlot(rho)
    figure
    subplot(1,2,1)
    bar3(real(rho));
    axis([0.5, 4.5, 0.5, 4.5, -1.2, 1.2]);
    title('Re[\rho]');
    
    subplot(1,2,2)
    bar3(imag(rho));
    axis([0.5, 4.5, 0.5, 4.5, -1.2, 1.2])
    title('Im[\rho]');

end