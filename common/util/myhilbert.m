function out = myhilbert(signal)
    % finds the hilbert transform of a signal in the frequency domain
    % compute FFT
    fsignal = fft(signal);
    n = length(signal);
    midpoint = ceil(n/2);
    
    % construct the analytic signal by setting all negative frequency
    % components to zero and multiplying positive components by two (except
    % DC and Nyquist terms)
    kernel = zeros(n,1);
    kernel(1) = 1;
    if 2*fix(n/2) == n % n is even
        kernel(midpoint + 1) = 1;
    end
    kernel(2:midpoint) = 2;
    
    out = ifft(kernel .* fsignal(:));
end