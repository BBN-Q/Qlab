function [times, freqs] = fitramsey2D(xdata, ydata)
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
    %h = figure;
end

times = zeros(1,size(ydata,2));
freqs = zeros(1,size(ydata,2));
beta = zeros(1,4);

for cnt=1:size(ydata,2)
    y = ydata(:,cnt);

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

    % initial guess for amplitude is max - mean
    amp = max(y) - mean(y);

    % initial guess for Rabi time is length/3
    trabi = max(xdata)/3.;

    % use largest FFT frequency component to seed Rabi frequency
    yfft = fft(y);
    [freqamp freqpos] = max(abs( yfft(2:floor(end/2)) ));
    frabi = 2*pi*(freqpos-1)/xdata(end);

    if cnt == 1
        p = [mean(y) amp trabi frabi 0];
    else
        p = beta;
    end

    [beta,r,j] = nlinfit(xdata, y, rabif, p);

    % figure(h)
    % subplot(3,1,2:3)
    % plot(xdata,y,'o')
    % hold on
    % plot(xdata_finer,rabif(beta,xdata_finer),'-r')
    % xlabel('Time [ns]')
    % ylabel('<\sigma_z>')
    % hold off
    % subplot(3,1,1)
    % bar(xdata,r)
    % axis tight
    % xlabel('Time [ns]')
    % ylabel('Residuals [V]')
    % title(plotTitle)
    % 
    % subplot(3,1,2:3)
    % ylim([-1.05 1.05])

    t2 = beta(3);
    ci = nlparci(beta,r,j);
    t2error = (ci(3,2)-ci(3,1))/2;
    detuning = abs(beta(4))/2/pi; % in GHz, assuming time is in ns

    % annotate the graph with T_Rabi result
    % text(xdata(end-1), max(y), ...
    %     sprintf(['T_{2}^{*} = %.0f +/- %.0f ns \n' ...
    %         '\\delta/2\\pi = %.2f MHz'], t2, t2error, detuning*1e3), ...
    %     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
    % axis tight

    times(cnt) = t2;
    freqs(cnt) = detuning;
end