function S21 = Lorentzian(FitParameter, f)
    f0 = FitParameter(1); % Resonance Frequency
    offset = FitParameter(2); % offset
    A = FitParameter(3); % Lorentzian amplitude
    kappa = FitParameter(4); % kappa
    
    S21 = offset + A./sqrt(1 + (f - f0).^2./kappa.^2);
end