function [n, nerr] = fit_photon_number(xdata, ydata, params)
% Fit photon number from a Ramsey following a measurement pulse. 
% see McClure et al., Phys. Rev. Applied 5, 011001 

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

% input params:
%  1 - cavity decay rate kappa (MHz)
%  2 - detuning Delta (2*pi*MHz)
%  3 - dispersive shift 2Chi (2*pi*MHz)
%  4 - Ramsey decay time T2* (us)
%  5 - exp(-t_meas/T1), to include relaxation during msm't
%  6 - initial qubit state (0/1)

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
    if ~isfield(figHandles, 'Ramsey') || ~ishandle(figHandles.('Ramsey'))
        figHandles.('Ramsey') = figure('Name', 'Ramsey');
        h = figHandles.('Ramsey');
    else
        h = figure(figHandles.('Ramsey')); clf;
    end
    plotTitle = 'Fit to qubit frequency with variable photon number';
end

y = ydata(:);
drawnow()

% if xdata is a single value, assume that it is the time step
if length(xdata) == 1
    xdata = 0:xdata:xdata*(length(y)-1);
end
% construct finer step tdata for plotting fit
xdata_finer = linspace(0, max(xdata), 4*length(xdata));

xdata = xdata(:);
xdata_finer = xdata_finer(:);

model = @(p, tdata)((-imag(exp(-(1/params(4)+params(2)*1j).*tdata + (p(1)-1*p(2)*params(3)*(1-exp(-((params(1) + params(3)*1j).*tdata)))/(params(1)+params(3)*1j))*1j)))*(1+(params(5)-1)*params(6))...
     +params(6)*(-imag(exp(-(1/params(4)+params(2)*1j).*tdata + (p(1)+pi-1*p(2)*params(3)*(1-exp(-((params(1) + params(3)*1j).*tdata)))/(params(1)+params(3)*1j))*1j)))*(1-params(5)));

p = [0 0.5];
[beta,r,j] = nlinfit(xdata, y, model, p);
ci = nlparci(beta,r,j);
n = beta(2); %photon number
nerr = (ci(2,2)-ci(2,1))/2;

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

 text(xdata(end-1)/1e3, 0.8, ...
     sprintf('n_0 = %.2f +/- %.2f \n', n, nerr), ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');


