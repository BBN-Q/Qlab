function piAmp = analyzeRabiAmp(data)
    xpts = 0:100:80*100; % this must match the settings of RabiChannelAmpSequence
                         % TODO: store this in a common location
    xpts = xpts(:);
    data = data(:);
    % use largest FFT frequency component to seed Rabi frequency
    yfft = fft(data);
    [tmp freqpos] = max(abs( yfft(2:floor(end/2)) ));
    frabi = max(freqpos,1)/xpts(end);
    
    % model A + B * cos(w t + phi)
    rabif = inline('p(1) - p(2)*cos(2*pi*p(3)*xdata + p(4))','p','xdata');

    % initial guess for amplitude is max - min
    amp = 0.5*(max(data) - min(data));
    offset = mean(data);
    phase = 0;
    % check sign of amp
    if data(1) > offset
        amp = -amp;
    end
    
    p = [offset amp frabi phase];
    [beta,r,j] = nlinfit(xpts, data, rabif, p);
    
    frabi = abs(beta(3));
    piAmp = 0.5/frabi;
end