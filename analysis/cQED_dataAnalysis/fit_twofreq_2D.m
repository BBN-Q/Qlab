function [T2sA, T2sB, freqsA, freqsB] = fit_twofreq_2D(xdata, ydata,filename)
% Fits 2D Ramsey scan
%
% [times, freqs] = fit_twofreq_2D(xdata, ydata)
% xdata : vector of time samples
% ydata : matrix of data (each Ramsey experiment along a row)
% filename: data identifier

numScans = size(ydata,1);
T2sA = zeros(numScans, 1);
T2sB = zeros(numScans, 1);
freqsA = zeros(numScans, 1);
freqsB = zeros(numScans, 1);
dT2sA = zeros(numScans, 1);
dT2sB = zeros(numScans, 1);
dfreqsA = zeros(numScans, 1);
dfreqsB = zeros(numScans, 1);

beta = zeros(1,4);

for cnt=1:numScans
    y = ydata(cnt,:);

    %Use KT estimation to get initial guesses
    [freqs, Ts, amps] = KT_estimation(y, xdata(2)-xdata(1),2);

    filterIdx = Ts > 0;
    freqs = freqs(filterIdx);
    Ts = Ts(filterIdx);
    amps = amps(filterIdx);
    phases = angle(amps);
    amps = abs(amps);
    idx1 = 1;
    if(length(amps)>1)
        idx2 = 2;
    else
        idx2 = 1;
    end
    % model A + B Exp(-t/C) * cos(D t + F) + G Exp(-t/H) * cos(I t + J)
    model = @(p, t) p(1) + p(2)*exp(-t/p(3)).*cos(p(4)*t + p(5)) + p(6)*exp(-t/p(7)).*cos(p(8)*t + p(9));
    
    p = [mean(y) amps(idx1) Ts(idx1) 2*pi*freqs(idx1) phases(idx1) amps(idx2) Ts(idx2) 2*pi*freqs(idx2) phases(idx2)];
    [beta,r,j] = nlinfit(xdata, y, model, p);

    figure(100)
    subplot(3,1,2:3)
    plot(xdata,y,'o')
    hold on
    % construct finer step tdata for plotting fit
    xdata_finer = linspace(0, max(xdata), 4*length(xdata))';
    plot(xdata_finer,model(beta,xdata_finer),'-r')
    xlabel('Time [ns]')
    ylabel('<\sigma_z>')
    hold off
    subplot(3,1,1)
    bar(xdata,r)
    axis tight
    xlabel('Time [ns]')
    ylabel('Residuals [V]')
    
    subplot(3,1,2:3)
    %ylim([-1.05 1.05])
    
    %pause(.2)

    t2 = beta(3);
    ci = nlparci(beta,r,j);
    t2error = (ci(3,2)-ci(3,1))/2;
    detuning = abs(beta(4))/2/pi; % in GHz, assuming time is in ns
    T2s(cnt) = t2;
    freqs(cnt) = detuning;
    
    t2A = beta(3);
    ci = nlparci(beta,r,j);
    t2Aerror = (ci(3,2)-ci(3,1))/2;
    t2B = beta(7);
    ci = nlparci(beta,r,j);
    t2Berror = (ci(7,2)-ci(7,1))/2;
    detuningA = abs(beta(4))/2/pi; % in GHz, assuming time is in ns
    detuningAerror = (ci(4,2)-ci(4,1))/2;
    detuningB = abs(beta(8))/2/pi;
    detuningBerror = (ci(8,2)-ci(8,1))/2;
    T2sA(cnt) = t2A;
    T2sB(cnt) = t2B;
    detuningvec = [detuningA, detuningB];
    [freqsA(cnt),indmax] = max(detuningvec);
    [freqsB(cnt),~] = min(detuningvec);
    if indmax(1)==1
        dfreqsA(cnt) = detuningAerror;
        dfreqsB(cnt) = detuningBerror;
    else
        dfreqsA(cnt) = detuningBerror;
        dfreqsB(cnt) = detuningAerror;
    end
    if abs(detuningAerror/detuningA)<0.03 %disregards bad fits
        freqsA(cnt) = detuningA;
    else
        freqsA(cnt) = NaN;
    end
    if abs(detuningBerror/detuningB)<0.03
        freqsB(cnt) = detuningB;
    else
        freqsB(cnt) = NaN;
    end
    dT2sA(cnt) = t2Aerror;
    dT2sB(cnt) = t2Berror;
    dfreqsA(cnt) = detuningAerror;
    dfreqsB(cnt) = detuningBerror;
end
    figure(202);
    xaxis=1:length(T2sA);
    errorbar(xaxis, freqsA*1000,dfreqsA*1000,'r.-','MarkerSize',12)
    hold on; errorbar(xaxis, freqsB*1000, dfreqsB*1000, 'b.-', 'MarkerSize',12);
    ylim([0,inf]);
    xlabel('Repeat number');
    ylabel('detuning (MHz)');
    title(strrep(filename, '_', '\_'));
    %fprintf('Average T1 = %.1f us\n', mean(T1/1000));
end