function [t3, t3error] = fitrabisloped(xdata, ydata)
% Fits rabi data in time range (x-axis) from start to end using a decaying
% sine.

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
end
y = ydata;

% if xdata is a single value, assume that it is the time step
if length(xdata) == 1
    xdata = 0:xdata:xdata*(length(y)-1);
end

% model A + B Exp(-t/tau) * cos(w t + phi) + C t
rabif = inline('p(1) + p(2)*exp(-tdata/p(3)).*cos(p(4)*tdata + p(5)) + p(6)*tdata','p','tdata');

% initial guess for amplitude is y(1) - mean
amp = y(1) - mean(y);
%if y(1) < mean(y), amp = -1 * amp; end

% initial guess for Rabi time is length/3
trabi = max(xdata)/3.;

% use largest FFT frequency component to seed Rabi frequency
yfft = fft(ydata);
[freqamp freqpos] = max(abs( yfft(2:floor(end/2)) ));
frabi = 2*pi*(freqpos-1)/xdata(end);

p = [mean(y) amp trabi frabi 0 1e-6];

tic
[beta,r,j] = nlinfit(xdata, y, rabif, p);
toc

figure
subplot(3,1,2:3)
plot(xdata,y,'o')
hold on
plot(xdata,rabif(beta,xdata),'-r')
xlabel('Time [ns]')
ylabel('Amp [V]')
hold off
subplot(3,1,1)
bar(xdata,r);
xlabel('Time [ns]')
ylabel('Residuals [V]')
axis tight

t3 = beta(3);
ci = nlparci(beta,r,j);
t3error = (ci(3,2)-ci(3,1))/2;

% annotate the graph with T_Rabi result
subplot(3,1,2:3)
text(xdata(end-1), max(y), sprintf('T_{Rabi} = %.0f +/- %.0f ns', t3, t3error), ...
    'HorizontalAlignment', 'right');

% if you want confidence bands, use something like:
% ci = nlparci(beta,r,j);
% [ypred,delta] = nlpredci(rabif,x,beta,r,j);