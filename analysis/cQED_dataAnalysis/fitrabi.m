function [t3, t3error,amp] = fitrabi(xdata, ydata)
% Fits rabi data in time range (x-axis) from start to end using a decaying
% sine.

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
    % save figure title
    plotTitle = get(get(gca, 'Title'), 'String');
else
    h = figure;
    plotTitle = '';
end
y = ydata(:);

% if xdata is a single value, assume that it is the time step
if length(xdata) == 1
    xdata = 0:xdata:xdata*(length(y)-1);
end
% construct finer step tdata
xdata_finer = linspace(0, max(xdata), 4*length(xdata));

xdata = xdata(:);
xdata_finer = xdata_finer(:);

% model A + B Exp(-t/tau) * cos(w t + phi)
rabif = inline('p(1) + p(2)*exp(-tdata/p(3)).*cos(p(4)*tdata + p(5))','p','tdata');

% initial guess for amplitude is y(max) - mean
amp = y(max) - mean(y);

% initial guess for Rabi time is length/3
trabi = max(xdata)/3.;

% use largest FFT frequency component to seed Rabi frequency
yfft = fft(ydata);
[freqamp freqpos] = max(abs( yfft(2:floor(end/2)) ));
frabi = 2*pi*(freqpos-1)/xdata(end);

p = [mean(y) amp trabi frabi 0];

tic
[beta,r,j] = nlinfit(xdata, y, rabif, p);
toc

figure(h)
subplot(3,1,2:3)
plot(xdata,y,'o')
hold on
plot(xdata_finer,rabif(beta,xdata_finer),'-r')
xlabel('Time [ns]')
ylabel('Amp [V]')
hold off
subplot(3,1,1)
bar(xdata,r);
xlabel('Time [ns]')
ylabel('Residuals [V]')
axis tight
title(plotTitle)

t3 = beta(3);
ci = nlparci(beta,r,j);
t3error = (ci(3,2)-ci(3,1))/2;
frabi = abs(beta(4))/2/pi; % in GHz, assuming time is in ns
frabi_error = abs(ci(4,2)-ci(4,1))/4/pi; %in GHZ

% annotate the graph with T_Rabi result
subplot(3,1,2:3)
text(xdata(end-1), max(y),...
    sprintf(['T_{Rabi} = %.0f +/- %.0f ns\n'...
    '\\Omega_{R}/2\\pi = %.2f +/- %.2f MHz'], t3, t3error, frabi*1e3, frabi_error*1e3), ...
    'HorizontalAlignment', 'right');

% if you want confidence bands, use something like:
% ci = nlparci(beta,r,j);
% [ypred,delta] = nlpredci(rabif,x,beta,r,j);