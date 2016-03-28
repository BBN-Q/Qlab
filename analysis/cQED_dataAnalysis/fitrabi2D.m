function [frabivec, dfrabivec] = fitrabi2D(xdata, ydata)
% Fits 2D Ramsey scan
%
% [times, freqs] = fitramsey2D(xdata, ydata)
% xdata : vector of time samples
% ydata : matrix of data (each Ramsey experiment along a row)

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

numScans = size(ydata,1);
frabivec = zeros(numScans, 1);
dfrabivec = zeros(numScans, 1);

for cnt=1:numScans
    y = ydata(cnt,:);

% model A + B Exp(-t/tau) * cos(w t + phi)
%rabif = inline('p(1) + p(2)*exp(-tdata/p(3)).*cos(p(4)*tdata + p(5))','p','tdata');
rabif = inline('p(1) + p(2).*cos(p(3)*tdata + p(4))','p','tdata');

% initial guess for amplitude is y(1) - mean
amp = max(y) - mean(y);

% model A + B Exp(-t/tau) * cos(w t + phi)
yfft = fft(y);
[~, freqpos] = max(abs( yfft(2:floor(end/2)) ));
frabi = 2*pi*(freqpos*1)/xdata(end);

%p = [mean(y) amp trabi frabi pi/2];
p = [mean(y) amp frabi 0];

tic
[beta,r,j] = nlinfit(xdata, y, rabif, p);
toc

    if ~isfield(figHandles, 'Rabi') || ~ishandle(figHandles.('Rabi'))
        figHandles.('Rabi') = figure('Name', 'Rabi');
    else
        figure(figHandles.('Rabi')); clf;
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

ci = nlparci(beta,r,j);
frabivec(cnt) = abs(beta(3))/2/pi; % in GHz, assuming time is in ns
dfrabivec(cnt) = abs(ci(3,2)-ci(3,1))/4/pi; %in GHZ
pause(0.1)
end
end