function [S21min, Ql, baseline, f0, a] = fitHanger(xdata, ydata, showResiduals)

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
[Vmin, f0index] = min(ydata);
[Vmax, ~] = max(ydata);
y = y / Vmax;
%amp = amp - offset;

% initial guess for f0 from position of max point
f0 = xdata(f0index);

%initial guess for alpha
a = 0;

Qi = 10000;
Qc=Qi*(Vmin/Vmax)/(1-Vmin/Vmax);	

% find positions of half-height points
%startx = find(ydata(1:f0index) < 2*S21min + offset, 1);
%endx = f0index + find(ydata(f0index:end) > 2*S21min + offset, 1);
startx = 1; endx = length(xdata); % no estimate
kappa = xdata(endx) - xdata(startx);

p = [Qc/(Qi+Qc)	 Qc*Qi/(Qc+Qi) 1 f0 0 0];

%p = 1e3*[0.0001    6.5000    0.0010    0.0063535         0];


tic
[beta,r,j] = nlinfit(xdata, y, @Hanger, p);
toc

figure
if showResiduals, subplot(3,1,2:3), end
plot(xdata,y,'o')
hold on
plot(xdata_finer,Hanger(beta,xdata_finer),'-r')
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
%ylim([S21min offset])

f0 = beta(4);
ci = nlparci(beta,r,j);
f0error = (ci(4,2)-ci(4,1))/2;

Q = abs(beta(2));
Qerror = (ci(2,2)-ci(2,1))/2;

S21min = beta(1);
kappa  = abs(f0/Q*1e9);
kerror = kappa * sqrt( (f0error/f0)^2 + (Qerror/Q)^2 );

% annotate the graph with fit result
text(xdata(end-1), max(y), sprintf(['f0 = %.5f GHz +/- %.3g kHz\n' ...
     'Q = %.3f +/- %.3f\n' ...
     'k = %.3f MHz +/- %.3f MHz\n'], ...
     f0, f0error*1e6, Q, Qerror, kappa/1e6, kerror/1e6), ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
