rindex = 2; % which resonator do you want to look at?
throwaway = 1; % # of temperatures to ignore
startindex = 1; % cutoff features on left side of data

clear f0s Qrs Qcs Qis Qis2

%data points per sweep
points=data{rindex}{1}.CFG.InitParams.pna.ordered.sweep_points;

%center frequncy of PNA scan (Hz)
cfreq=data{rindex}{1}.CFG.ExpParams.meas_resp.sweep_center.start;

%span of PNA scan (Hz)
span=data{rindex}{1}.CFG.InitParams.pna.ordered.sweep_span;

%rescale to GHz
cfreq = cfreq/1e9;
span = span/1e9;

% define frequency range
frequency=linspace(cfreq-span/2,cfreq+span/2,points);

for tindex = 1:length(temperatures)-throwaway % loop through temperatures

    reald = data{rindex}{tindex}.Data(1:2:end)';
    imagd = data{rindex}{tindex}.Data(2:2:end)';
    magd = sqrt(reald.^2 + imagd.^2);

    if isempty(s21fig)
        s21fig = figure;
    else
        figure(s21fig)
    end
    subplot(1,2,1)
    plot(frequency, magd)
    title(sprintf('Resonator %d', rindex))
    xlabel('Frequency [GHz]')
    ylabel('Magnitude of S21')
    axis tight
    hold on

    % Before doing the circle fit, find the approximate location of the
    % resonance. Otherwise, will end up fitting the circle from the cable
    % delay.
    if tindex == 1
        [minS21, resfreqindex] = min(magd(startindex:end));
        resfreqindex = resfreqindex + startindex - 1;
    else % use last resonance frequency as upper bound in search
        [minS21, resfreqindex] = min(magd(startindex:resfreqindex));
        resfreqindex = resfreqindex + startindex - 1;
    end
    subspan = 750; % number of frequency points to take around the minimum
    subindex = (resfreqindex - subspan/2):(resfreqindex + subspan/2);

    delay=34E-9;    % measured electrical delay on PNA
                    % signiture is a squashed or skew circle,  delay rotates
                    % and reshapes this  but in theory this should be a fit
                    % parameter that includes the circle fit routine.
    ang=angle(reald+1i*imagd)+2*pi*frequency*1e9*delay;
    x=magd.*cos(ang);
    y=magd.*sin(ang);
    [xc,yc,R] = circfit(x(subindex),y(subindex));
    zc=sqrt(xc^2+yc^2);
    t=linspace(0,2*pi,length(subindex));
    xf=R.*cos(t)+xc;
    yf=R.*sin(t)+yc;

    fitS21Mag=sqrt(xf.^2+yf.^2);

    subplot(1,2,2)
    plot(x(subindex),y(subindex),xf,yf)

    if tindex == 1
        f0Guess = frequency(resfreqindex);
        slopeGuess = (magd(end)^2 - magd(1)^2)/span;
        A0Guess = magd(1)^2 + slopeGuess*(f0Guess-frequency(1));
        AmpGuess = A0Guess - min(magd)^2;
        skewGuess = -0.1;
        QrGuess = 5000;
        %QcGuess=QrGuess/(2*r);
        %QiGuess = QcGuess*QrGuess/(QcGuess-QrGuess);
    else % use last fit values to seed
        f0Guess = frequency(resfreqindex);
    %     A0Guess = Fit{tindex-1}.FitParameters(2);
        slopeGuess = Fit{tindex-1}.FitParameters(3);
        A0Guess = Fit{tindex-1}.FitParameters(2) + slopeGuess * (f0Guess - Fit{tindex-1}.FitParameters(1));
        AmpGuess = Fit{tindex-1}.FitParameters(4);
        skewGuess = Fit{tindex-1}.FitParameters(5);
        QrGuess = Fit{tindex-1}.FitParameters(6);
    end

    % subspan = 1000; % number of frequency points to take around the minimum
    subspan =  int32(8*f0Guess/QrGuess/span*points);
    if (subspan > 2000), subspan = 2000; end
    loweri = resfreqindex - subspan/2;
    upperi = resfreqindex + subspan/2;
    if (loweri < 1), loweri = 1; end
    if (upperi > points), upperi = points; end
    subindex = loweri:upperi;
    
    %FitParameterStart = [f0Guess offset linear_slope amplitude skew Qr];
    FitParameterStart = [f0Guess A0Guess slopeGuess AmpGuess skewGuess QrGuess];
    LB = [frequency(loweri)   min(magd.^2) -1E-3 0.5*AmpGuess -0.2 1  ];
    UB = [frequency(upperi) max(magd.^2)  1E-3   2*AmpGuess  0.2 1E6];

    % Plot the initial guess and the data to see how bad initial guess is
    [ChiSquaredInitialValue, GuessedS21] = ResChiSqr(FitParameterStart, frequency(subindex), magd(subindex));
    % GuessedS21 = skewedLorentzian(FitParameterStart, frequency(subindex));
    subplot(1,2,1)
    plot(frequency(subindex), sqrt(GuessedS21),'r--','linewidth',2)
    pause(0.5)

    % plot |S21|^2
    cla
    plot(frequency(subindex), magd(subindex).^2)
    plot(frequency(subindex), GuessedS21,'r--','linewidth',2)
    axis tight
    pause(0.25)

    % Call the fitting function
    options = optimset('LargeScale','off','MaxIter',10000, 'MaxFunEvals', 10000000,...
        'TolX', 1e-10, 'TolFun', 1e-10, 'Display', 'notify');

    [FitParameters] = ... 
        fminsearchbnd(@ResChiSqr, FitParameterStart, LB, UB, options, frequency(subindex), magd(subindex));

    % Plot final fits and the data together to see how bad the final fit is
    [ChiSquaredMinimisedValue, PredictedS21,chisq] = ResChiSqr(FitParameters, frequency(subindex), magd(subindex));

    % [FitParamters,r,j] = nlinfit(frequency(subindex), magd(subindex).^2, @skewedLorentzian, FitParameterStart);

    Qr = FitParameters(6);
    Qc = (zc+R)/(2*R)*Qr;
    Qi = Qr*Qc/(Qc-Qr);

    Fit{tindex}.FitParameters = FitParameters';
    Fit{tindex}.chisq = chisq;
    % estimate data error from differences between first m points
    m = 100;
    sigma = sum((magd(2:m+1) - magd(1:m)).^2)/(2*m);
    Fit{tindex}.rchisq = chisq/sigma/(double(subspan) - length(FitParameters)); % reduced chi squared
    f0s(tindex) = FitParameters(1);
    Qrs(tindex) = Qr;
    Qcs(tindex) = Qc;
    Qis(tindex) = Qi;

    % ci = nlparci(FitParameters,r,j);

    cla
    plot(frequency(subindex), magd(subindex).^2)
    % PredictedS21 = skewedLorentzian(FitParameters, frequency(subindex));
    plot(frequency(subindex), PredictedS21,'r--','linewidth', 2)
    axis tight
    hold off
    pause(0.5)

end

% assume Qc is temperature-independent (take avg of lowest T values)
Qc = mean(Qcs(1:4));
for tindex = 1:length(temperatures)-throwaway
    Qis2(tindex) = Qrs(tindex)*Qc/(Qc-Qrs(tindex));
end

figure
subplot(2,1,1)
plot(temperatures(1:end-throwaway), f0s, '.-')
xlabel('Temperature (K)')
ylabel('Resonance Frequency (GHz)')
subplot(2,1,2)
plot(temperatures(1:end-throwaway), Qrs, '.-')
hold on
plot(temperatures(1:end-throwaway), Qcs, 'g.-')
plot(temperatures(1:end-throwaway), Qis, 'r.-')
plot(temperatures(1:end-throwaway), Qis2, 'k.-')
xlabel('Temperature (K)')
ylabel('Q')
l = legend({'Qr', 'Qc', 'Qi', 'Qi (const Qc)'}, 'Location', 'NorthEast');
set(l, 'Box', 'off')