function [T2s, t2error, fit_freqs, fit_freqs_err] = fitramsey2D(xdata, data)
% Fits 2D Ramsey scan
%
% [times, freqs] = fitramsey2D(xdata, ydata)
% xdata : vector of time samples
% ydata : matrix of data (each Ramsey experiment along a row)

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

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

% data = data';
numScans = size(data,1);
T2s = zeros(numScans, 1);
fit_freqs = zeros(numScans, 1);
xdata = xdata';

beta = zeros(1,4);

for cnt=1:numScans
    y = data(cnt,:);

    %Use KT estimation to get initial guesses
    [freqs, Ts, amps] = KT_estimation(y, xdata(2)-xdata(1),2);
    [~, biggestC] = max(abs(amps));

    % model A + B Exp(-t/tau) * cos(w t + phi)
    rabif = inline('p(1) + p(2)*exp(-tdata/p(3)).*cos(p(4)*tdata + p(5))','p','tdata');
    p = [mean(y) abs(amps(biggestC)) Ts(biggestC) 2*pi*freqs(biggestC) 0];
    [beta,r,j] = nlinfit(xdata, y, rabif, p);

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
    plot(xdata_finer,rabif(beta,xdata_finer),'-r')
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
    
    pause(.2)

    t2 = beta(3);
    ci = nlparci(beta,r,j);
    t2error(cnt) = (ci(3,2)-ci(3,1))/2;
    detuning = abs(beta(4))/2/pi; % in GHz, assuming time is in ns
    fit_freqs_err(cnt) = abs(ci(3,2)-ci(3,1))/4/pi;
    T2s(cnt) = t2;
    fit_freqs(cnt) = detuning;
end
