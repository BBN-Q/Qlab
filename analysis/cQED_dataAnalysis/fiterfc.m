function [t0, s] = fiterfc(xdata, ydata)
% Fits time domain data to an erfc(t-t0/s) response

showResiduals = false;

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
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

% model A * erfc((t-t0)/s) - 1
modelf = inline('p(1) * erfc((t - p(2))./p(3)) + 1','p','t');

% initial parameter guesses
amp = -1;
t0 = 40;
s = 5;

p = [amp t0 s];

tic
[beta,r,j] = nlinfit(xdata, y, modelf, p);
toc

figure
if showResiduals, subplot(3,1,2:3); end
plot(xdata,y,'o')
hold on
plot(xdata_finer,modelf(beta,xdata_finer),'-r')
%plot(xdata_finer,modelf(p,xdata_finer),'-r')
xlabel('Time [ns]')
ylabel('<\sigma_z>')
hold off
if showResiduals
    subplot(3,1,1)
    bar(xdata,r);
    xlabel('Time [ns]')
    ylabel('Residuals')
    axis tight
end
t0 = beta(2);
s = beta(3);
ci = nlparci(beta,r,j);
t0error = (ci(2,2)-ci(2,1))/2;
serror = (ci(3,2)-ci(3,1))/2;

% annotate the graph with fit result
if showResiduals, subplot(3,1,2:3); end
text(xdata(end-1), -0.5, sprintf('t_0 = %.0f +/- %.0f ns\ns = %.0f +/- %.0f ns', t0, t0error, s, serror), ...
    'HorizontalAlignment', 'right');
