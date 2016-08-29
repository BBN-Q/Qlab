function [t2, detuning, detuning2] = fit_two_freq(xdata, ydata)
% Fits ramsey data in time range (x-axis) from start to end using a decaying
% sinusoid.

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
    % save figure title
    plotTitle = get(get(gca, 'Title'), 'String');
    %convert xaxis to ns
    if ~isempty(strfind(get(get(gca, 'xlabel'), 'String'), '\mus')) || ~isempty(strfind(get(get(gca, 'xlabel'), 'String'), 'us'))
        xdata = xdata*1e3;
    elseif ~isempty(strfind(get(get(gca, 'xlabel'), 'String'), 'ms'))
        xdata = xdata*1e6;
    elseif ~isempty(strfind(get(get(gca, 'xlabel'), 'String'), 's'))
        xdata = xdata*1e9;
    end
else
    h = figure(401); %fixed window for this figure
    plotTitle = '';
end

y = ydata(:);

% if xdata is a single value, assume that it is the time step
if length(xdata) == 1
    xdata = 0:xdata:xdata*(length(y)-1);
end
% construct finer step tdata for plotting fit
xdata_finer = linspace(0, max(xdata), 4*length(xdata));

xdata = xdata(:);
xdata_finer = xdata_finer(:);

%Use KT estimation to get a guess for the fit
[freqs,Ts,amps] = KT_estimation(ydata, xdata(2)-xdata(1),3);
filterIdx = Ts > 0;
freqs = freqs(filterIdx);
Ts = Ts(filterIdx);
amps = amps(filterIdx);
phases = angle(amps);
amps = abs(amps);
idx1 = 1;
idx2 = 2;

fprintf('KT Estimation results\n');
fprintf('tau1 = %.1fus; f1 = %.0fkHz\n', Ts(idx1)/1e3, freqs(idx1)*1e6);
if length(freqs)>1
    fprintf('tau2 = %.1fus; f2 = %.0fkHz\n', Ts(idx2)/1e3, freqs(idx2)*1e6);
    
    % model A + B Exp(-t/C) * cos(D t + F) + G Exp(-t/H) * cos(I t + J)
    model = @(p, t) p(1) + p(2)*exp(-t/p(3)).*cos(p(4)*t + p(5)) + p(6)*exp(-t/p(7)).*cos(p(8)*t + p(9));
    p = [mean(y) amps(idx1) Ts(idx1) 2*pi*freqs(idx1) phases(idx1) amps(idx2) Ts(idx2) 2*pi*freqs(idx2) phases(idx2)];
    
    try
        [beta,r,j] = nlinfit(xdata, y, model, p);
    catch
        fprintf('2-freq. fit failed\n')
        [t2, detuning] = fitramsey(xdata, ydata);
        detuning2 = detuning;
        return
    end
else
    fprintf('2-freq. fit failed\n')
    [t2, detuning] = fitramsey(xdata, ydata);
    detuning2 = detuning;
    return
end

figure(h)
subplot(3,1,2:3)
plot(xdata/1e3,y,'o')
hold on
plot(xdata_finer/1e3,model(beta,xdata_finer),'-r')
xlabel('Time [\mus]')
ylabel('<\sigma_z>')
hold off
subplot(3,1,1)
bar(xdata/1e3,r)
axis tight
xlabel('Time [\mus]')
ylabel('Residuals [V]')
title(plotTitle)

subplot(3,1,2:3)
ylim([-1.05 1.05])

t2 = beta(3);
ci = nlparci(beta,r,j);
t2error = (ci(3,2)-ci(3,1))/2;
detuning = abs(beta(4))/2/pi; % in GHz, assuming time is in ns
detuningError = (ci(4,2)-ci(4,1))/2;
detuning2 = abs(beta(8))/2/pi;
detuningError2 = (ci(8,2)-ci(8,1))/2;

% annotate the graph with T_Rabi result
text(xdata(end-1)/1e3, max(y), ...
    sprintf(['T_{2}^{*} = %.1f +/- %.1f us \n' ...
        '\\delta/2\\pi = %.3f +/- %.3f MHz\n'...
        '\\delta/2\\pi = %.3f +/- %.3f MHz'], t2/1e3, t2error/1e3, detuning*1e3, detuningError*1e3, detuning2*1e3, detuningError2*1e3), ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
axis tight
% if you want confidence bands, use something like:
% ci = nlparci(beta,r,j);
% [ypred,delta] = nlpredci(rabif,x,beta,r,j);

