function [piAmp, offsetPhase] = analyzeRabiAmp(data)
    
    numsteps = 40; %should be even
    stepsize = 400;
    xpts = [-(numsteps/2)*stepsize:stepsize:-stepsize stepsize:stepsize:(numsteps/2)*stepsize]';

    % use largest FFT frequency component to seed Rabi frequency
    yfft = fft(data);
    [~, freqpos] = max(abs( yfft(2:floor(end/2)) ));
    frabi = 0.5*max(freqpos,1)/xpts(end);
    
    % model A + B * cos(w t + phi)
    rabif = inline('p(1) - p(2)*cos(2*pi*p(3)*(xdata - p(4)))','p','xdata');

    % initial guess for amplitude is max - min
    amp = 0.5*(max(data) - min(data));
    offset = mean(data);
    phase = 0;
    % check sign of amp
    if data(end/2) > offset
        amp = -amp;
    end
    
    p = [offset amp frabi phase];
    [beta,~,~] = nlinfit(xpts, data(:), rabif, p);
    
    %The frequency tells us something about what a pi should calibrate to
    frabi = abs(beta(3));
    piAmp = 0.5/frabi;
    
    %The phase tell us somethign about the offset
    offsetPhase = beta(4);
    
end