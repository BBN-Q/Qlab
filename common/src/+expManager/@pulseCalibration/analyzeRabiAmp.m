function amp = analyzeRabiAmp(data)
    xpts = 0:200:40*200;
    % use largest FFT frequency component to seed Rabi frequency
    yfft = fft(data);
    [tmp freqpos] = max(abs( yfft(2:floor(end/2)) ));
    frabi = 2*pi*(freqpos-1)/xpts(end);
    
    % model A + B * cos(w t + phi)
    rabif = inline('p(1) + p(2)*cos(p(3)*t + p(4))','p','t');

    % initial guess for amplitude is max - min
    amp = max(data) - min(data);
end