function [T2sA, T2sB, dT2sA, dT2sB, freqsA, freqsB, dfreqsA, dfreqsB] = fit_twofreq_2D(xdata, ydata, filename)
% Fits 2D Ramsey scan
%
% xdata : vector of time samples
% ydata : matrix of data (each Ramsey experiment along a row)
% filename: data identifier

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    image = findall(h, 'Type', 'Image');
    xdata = get(image(1), 'xdata');
    ydata = get(image(1), 'ydata');
    data = get(image(1), 'CData');
    % save figure title
    plotTitle = get(get(gca, 'Title'), 'String');
else
    h = figure;
    plotTitle = 'Fit to a Damped Sinusoid';
end

numScans = size(ydata,1);

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

T2sA = zeros(numScans, 1);
T2sB = zeros(numScans, 1);
freqsA = zeros(numScans, 1);
freqsB = zeros(numScans, 1);
dT2sA = zeros(numScans, 1);
dT2sB = zeros(numScans, 1);
dfreqsA = zeros(numScans, 1);
dfreqsB = zeros(numScans, 1);

beta = zeros(1,9);

for cnt=1:numScans
    y = data(cnt,:);

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
    

    model = @(p, t) p(1) + p(2)*exp(-t/p(3)).*cos(p(4)*t + p(5)) + p(6)*exp(-t/p(7)).*cos(p(8)*t + p(9));
    p = [mean(y) amps(idx1) Ts(idx1) 2*pi*freqs(idx1) phases(idx1) amps(idx2) Ts(idx2) 2*pi*freqs(idx2) phases(idx2)];

    try
        [beta,r,j] = nlinfit(xdata, y, model, p);
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
    catch
        warning('2-freq fit failed on step %i\n', cnt)
        %fit single freq.
        [t2A, detuningA, t2Aerror, detuningAerror] = fitramsey(xdata, ydata);
        t2B = t2A; t2Berror = t2Aerror;
        detuningB = detuningA; detuningBerror = detuningAerror;
    end
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
    if abs(detuningAerror/detuningA)<0.1 %disregards bad fits
        freqsA(cnt) = detuningA;
    else
        freqsA(cnt) = NaN;
        T2sA(cnt) = NaN;
    end
    if abs(detuningBerror/detuningB)<0.1
        freqsB(cnt) = detuningB;
    else
        freqsB(cnt) = NaN;
        T2sB(cnt) = NaN;
    end
    dT2sA(cnt) = t2Aerror;
    dT2sB(cnt) = t2Berror;
    dfreqsA(cnt) = detuningAerror;
    dfreqsB(cnt) = detuningBerror;
    if ~isfield(figHandles, 'Ramsey') || ~ishandle(figHandles.('Ramsey'))
        figHandles.('Ramsey') = figure('Name', 'Ramsey');
    else
        figure(figHandles.('Ramsey')); clf;
    end
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
    ylim([-1.05 1.05])
    
    pause(.1)

   
end
freqsAt = max(freqsA, freqsB);
freqsBt = min(freqsA, freqsB);
freqsA = freqsAt;
freqsB = freqsBt;
    if ~isfield(figHandles, 'Ramsey_freqs') || ~ishandle(figHandles.('Ramsey_freqs'))
        figHandles.('Ramsey_freqs') = figure('Name', 'Ramsey_freqs');
    else
        figure(figHandles.('Ramsey_freqs')); clf;
    end
    xaxis=1:length(T2sA);
    errorbar(xaxis, freqsA*1000,dfreqsA*1000,'r.-','MarkerSize',12)
    hold on; errorbar(xaxis, freqsB*1000, dfreqsB*1000, 'b.-', 'MarkerSize',12);
    title(strrep(filename, '_', '\_'));
    ylim([0,inf]);
    xlabel('Repeat number');
    ylabel('detuning (MHz)');
    if ~isfield(figHandles, 'Ramsey_T2s') || ~ishandle(figHandles.('Ramsey_T2s'))
        figHandles.('Ramsey_T2s') = figure('Name', 'Ramsey_T2s');
    else
        figure(figHandles.('Ramsey_T2s')); clf;
    end
    xaxis=1:length(T2sA);
    errorbar(xaxis, T2sA/1000, dT2sA/1000,'r.-','MarkerSize',12)
    hold on; errorbar(xaxis, T2sB/1000, dT2sB/1000, 'b.-', 'MarkerSize',12);
    title(strrep(filename, '_', '\_'));
end
