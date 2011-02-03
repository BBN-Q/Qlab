function S21squared = skewedLorentzian(FitParameter, g)
    f0 = FitParameter(1); % Resonance Frequency
    A0 = FitParameter(2); % offset
    A1 = FitParameter(3); % linear slope
    A2 = FitParameter(4); % Lorentzian amplitude
    A3 = FitParameter(5); % skew
    Qr = FitParameter(6); % Quality Factor
    %S21 = abs((A0)*exp(2*pi*1i*g*delay).*(1-Qr/Qc*exp(1i*theta*pi/180)*1./(1+2*Qr*1i*(g/f0-1))));
    % skewed lonrenztian fit to Gao thesis to extract Qr.
    S21squared = A0+A1*(g-f0)-(A2-A3*(g-f0)/f0)./(1+4*Qr.^2*((g-f0)/f0).^2);
end