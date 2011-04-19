function [f0, f0error, kappa, kappaError] = fitLorentzian(xdata, ydata, showResiduals)
% Fits S21 amplitude data to a simple Lorentzian model and returns the
% center frequency and linewidth

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
end

if ~exist('showResiduals', 'var')
    showResiduals = false;
end

y = ydata(:);

% construct finer step xdata
xdata_finer = linspace(min(xdata), max(xdata), 4*length(xdata));

xdata = xdata(:);
xdata_finer = xdata_finer(:);

% initial guess for offset is y(1)
offset = y(1);

% initial guess for amplitude
[amp, f0index] = max(ydata);
amp = amp - offset;

% initial guess for f0 from position of max point
f0 = xdata(f0index);

% find positions of half-height points
startx = find(ydata(1:f0index) > amp/2 + offset, 1);
endx = f0index + find(ydata(f0index:end) < amp/2 + offset, 1);
kappa = xdata(endx) - xdata(startx);

p = [f0 offset amp kappa];

tic
[beta,r,j] = nlinfit(xdata, y, @Lorentzian, p);
toc

figure
if showResiduals, subplot(3,1,2:3), end
plot(xdata,y,'o')
hold on
plot(xdata_finer,Lorentzian(beta,xdata_finer),'-r')
xlabel('Frequency [GHz]')
ylabel('S21 [V]')
hold off
if showResiduals
    subplot(3,1,1)
    bar(xdata,r);
    xlabel('Frequency [GHz]')
    ylabel('Residuals [V]')
    subplot(3,1,2:3)
end
axis tight
ylim([offset-.1*amp offset+1.1*amp])

f0 = beta(1);
ci = nlparci(beta,r,j);
f0error = (ci(1,2)-ci(1,1))/2;

kappa = beta(4);
kappaError = (ci(4,2)-ci(4,1))/2;

Q = f0/kappa;
Qerror = Q * sqrt( (f0error/f0)^2 + (kappaError/kappa)^2 );

% annotate the graph with fit result
text(xdata(end-1), max(y), sprintf(['f0 = %.5f GHz +/- %.3g kHz\n' ...
    '\\kappa/2\\pi = %.3f +/- %.3f MHz\n' ...
    'Q_L = %.0f +/- %.0f'], ...
    f0, f0error*1e6, kappa*1e3, kappaError*1e3, Q, Qerror), ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
