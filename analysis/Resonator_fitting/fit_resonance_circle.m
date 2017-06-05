% Author/Date: Guilhem Ribeill 
%
% Copyright 2016 Raytheon BBN Technologies
%
%
% TODO: 
%   - Calculate fit errors by computing Jacobian numerically.
%   - Apply to 2D data. 
% References:
% [1]   S. Probst, F. B. Song, P. A. Bushev, A. V. Ustinov and M. Weides,
%       Efficient and robust analysis of complex scattering data under
%       noise in microwave resonators. arXiv:1410.3365, 2014.
% [2]   N. Chernov and C. J. Lesort, Least Squares Fitting of Circles,
%       Journal of Mathematical Imaging and Vision, 23: 239-252, 2005.
% [3]   M. S. Khalil, M. J. A. Stoutimore, F. C. Wellstood, and K. D.
%       Osborn, An anlysis method for asymmetric resonator transmission
%       applied to superconducting devices. J. Appl. Phys., 111, 054510
%       (2012)

function [fit_params, fit_errors] = fit_resonance_circle(varargin)
% FIT_RESONANCE_CIRCLE Fit to a resonance in the complex plane. Method
% follows Probst et al. [1]
%
% [FIT_PARAMS, FIT_ERRORS] = FIT_RESONANCE_CIRCLE(FREQ, DATA) fits complex
% valued data to a circle in the Re(data), Im(data) plane to extract
% resonant frequency, Qi, Qc, and the impedance mismatch angle [3].
% Compensates for cable phase delay and scaling/rotation of data by
% measurement chain.
% Optional string-value pairs:
%   - 'show_plot': Boolean, plot fits.
%   - 'demo': make some fake data and fit it.
    persistent figHandles;
    if isempty(figHandles)
        figHandles = struct();
    end
    parser = inputParser; 
    addRequired(parser, 'freq', @isnumeric);
    addRequired(parser, 'data', @isnumeric);
    addParameter(parser, 'show_plot', 0);
    addParameter(parser, 'demo', 0);
    parse(parser, varargin{:})
    if parser.Results.demo
        %generate example data
        f0 = 7.1;
        Qc = 2600;
        Qi = 1.7e5;
        tau = 1.734*pi;
        phi = 2.1*pi;
        Q = 1./(1/Qi + real(1./(Qc*exp(-1i*phi))));
        alpha = 1.2;
        A = 0.73;
        df = f0/Q;
        freq = linspace(f0-6*df, f0+6*df, 401);
        data = resonance_model([f0, phi, Q, Qc, tau, alpha, A],  freq);
        rand_phase = 2*pi*0.002*randn(size(freq));
        rand_amp = 0.01*randn(size(freq));
        data = data.*exp(-1i*rand_phase).*(1+rand_amp);
        show_plot = 1;
    else
        show_plot = parser.Results.show_plot;
        freq = parser.Results.freq;
        data = parser.Results.data;
    end
    assert(length(freq) == length(data), 'Frequency and transmission data must me the same length!');
    assert(length(data) > 20, 'Too few points!');
    freq = freq(:)';
    data = data(:)'; 
    [tau, alpha, A, figHandles] = calibrate_resonance(freq, data, show_plot, figHandles);
    S21_corr = apply_calibration(tau, alpha, A, freq, data);
    [f0, Qi, Qc, phi, figHandles] = fit_calibrated_resonance(freq, S21_corr, show_plot, figHandles);
    fprintf('Resonant frequency: %f\n', f0);
    fprintf('Internal quality factor: %f\n', Qi);
    fprintf('Coupling quality factor: %f\n', Qc);
    fprintf('Impedance mismatch angle: %f\n', phi);
    fit_params.f0 = f0;
    fit_params.Qi = Qi;
    fit_params.Qc = Qc;
    fit_params.phi = phi;
    fit_errors = []; %to do...
    
    if show_plot
        Q = 1./(1/Qi + real(1./(Qc*exp(-1i*phi))));
        fit = resonance_model([f0,abs(phi),Q,Qc,tau,alpha,A],freq);
        figure(figHandles.('calibration_plot'));
        subplot(2,1,1);hold on;
        plot(freq, 20*log10(abs(fit)), '-', 'LineWidth', 2);
        legend('data', 'fit');
    end

end

function S21 = resonance_model(params, f)
    fr = params(1); %resonant frequency
    phi = params(2); %angle offset in complex plane due to mismatch
    Q = params(3); %total Q
    Qc = params(4); %coupling Q
    tau = params(5); %phase delay
    alpha = params(6); %loss
    A = params(7); %overall amplitude
    S21 = A*exp(1i*alpha).*exp(-2*pi*1i*f*tau).*(1 - (Q/abs(Qc))*exp(1i*phi)./(1 + 2*1i*Q*(f/fr - 1)));
end

function [f0, Qi, Qc, phi, figHandles] = fit_calibrated_resonance(f, scaled_data, show_plot, figHandles)
    %Finally, extract experimental data from scaled data.
    [R, xc, yc] = fit_circle(real(scaled_data), imag(scaled_data));
    phi = -asin(yc/R);
    td = (real(scaled_data) - xc) + 1i*(imag(scaled_data) - yc);
    [f0, Qfit, ~, fit] = fit_phase(f, td);
    Qc = Qfit/(2*R*exp(-1i*phi));
    Qi = 1./(1./Qfit - real(1./Qc));  
    Qc = abs(Qc);
    if show_plot
        if ~isfield(figHandles, 'fit_plot') || ~ishandle(figHandles.('fit_plot'))
            figHandles.('fit_plot') = figure('Name', 'Resonator Fit');
        else
            figure(figHandles.('fit_plot')); clf;
        end
        subplot(2,1,1);hold on;
        plot(real(scaled_data), imag(scaled_data), '.', 'MarkerSize', 15);
        th = linspace(0,2*pi,101);
        plot(xc + R*cos(th), yc+R*sin(th), '-', 'LineWidth', 2);
        legend('data', 'fit');
        axis equal; grid on;
        xlabel('Re S_{21}', 'FontSize', 14);
        ylabel('Im S_{21}', 'FontSize', 14);
        set(gca, 'FontSize', 14);
        subplot(2,1,2);hold on;
        plot(f, unwrap(angle(td)), '.', 'MarkerSize', 15);
        plot(f, fit, '-', 'LineWidth', 2);
        grid on;
        xlabel('Frequency', 'FontSize', 14);
        ylabel('Phase [rad]', 'FontSize', 14);
        set(gca, 'FontSize', 14);

    end
    
end

function scaled_data = apply_calibration(tau, alpha, a, f, data)
    %%%Apply the calibration to resonator data to move it to canonical
    %position
    data = data.*exp(-1i*2*pi*f*tau);
    rot = [[cos(-alpha) -sin(-alpha)];[sin(-alpha) cos(-alpha)]];
    scaled_data = zeros(size(data));
    for j=1:length(data)
        v = rot*[real(data(j)); imag(data(j))];
        scaled_data(j) = (v(1) + v(2)*1i)/a;
    end
end

function [tau, alpha, a, figHandles] = calibrate_resonance(f, data, show_plot, figHandles)
    %%%Calibrate out cable delay and overall system gain in order to 
    %translate resonance circle to "canonical" position.
        
    %Fit to cable delay
    tau = fit_delay(f, data);
    Sp = exp(-1i*2*pi*f*tau).*data;
    %Get best-fit circle and translate to origin
    [R, xc, yc] = fit_circle(real(Sp), imag(Sp));
    Strans = (real(Sp)-xc) + 1i*(imag(Sp) - yc);
    %Calculate invariant \omega -> \infty point for the resonator data
    [~, ~, theta0, ~] = fit_phase(f, Strans);
    %not sure if this is reliable, may need to be just theta0
    P = xc + R*cos(theta0+pi) + 1i*(yc + R*sin(theta0+pi));
    a = abs(P);
    alpha = angle(P);
    Scorr = apply_calibration(tau, alpha, a, f, data);
    if show_plot  
        if ~isfield(figHandles, 'calibration_plot') || ~ishandle(figHandles.('calibration_plot'))
            figHandles.('calibration_plot') = figure('Name', 'Resonator Fit Calibration');
        else
            figure(figHandles.('calibration_plot')); clf;
        end
        subplot(2,1,1);
        plot(f, 20*log10(abs(data)), '.', 'MarkerSize', 15);
        grid on;
        xlabel('Frequency', 'FontSize', 14);
        ylabel('|S_{21}| [dB]', 'FontSize', 14);
        set(gca, 'FontSize', 14);
        subplot(2,1,2);
        hold on;
        plot(real(data), imag(data), '.', 'MarkerSize', 15);
        plot(real(Sp), imag(Sp), '.', 'MarkerSize', 15);
        plot(real(Scorr), imag(Scorr), '.', 'MarkerSize', 15);
        legend('Original Data', 'Delay-Corrected data', 'Canonical Position');
        axis equal; grid on;
        xlabel('Re S_{21}', 'FontSize', 14);
        ylabel('Im S_{21}', 'FontSize', 14);
        set(gca, 'FontSize', 14);
    end
    
end

%%%%% Functions for fitting frequency-dependent phase delay
function sse = delay_model(tau, f, data)
    %Model constant cable phase delay of resonator
    data = data.*exp(-2*pi*1i*f*tau);
    [R, xc, yc] = fit_circle(real(data), imag(data));
    X = real(data); Y = imag(data);
    sse = sum(R.^2 - (X-xc).^2 - (Y-yc).^2);
end

function tau = fit_delay(f, data)   
    %Phase delay adds a linear offset phase, so estimate first using
    %first and last 10 data points of data.
    phi = unwrap(angle(data));
    phi = [phi(1:10), phi(end-9:end)]';
    linfit = [ones(length(phi), 1) [f(1:10) f(end-9:end)]']\phi;
    model = @(t)delay_model(t, f, data);
    tau = fminsearch(model, linfit(2)/2/pi);
end

%%%%% Functions for frequency-phase fit of circle

function sse = phase_model(params, f, data, slope)
    %check direction of data
    theta0 = params(1);
    Q = params(2);
    f0 = params(3);
    fitfunc = theta0 + 2*slope*atan(2*Q*(1 - f/f0));
    sse = sum((fitfunc - unwrap(angle(data))).^2);
end

function [f0, Q, theta, fit] = fit_phase(f, data)
    %some initial guesses
    phi = unwrap(angle(data));
    %initial guesses
    [~,idx] = min(abs(phi-mean(phi)));  
    if mean(phi(1:10)) > mean(phi(end-9:end))
        j = find(phi-phi(idx) < pi/2, 1, 'first');
        k = find(phi-phi(idx) < -pi/2, 1, 'first');
        slope = 1;
    else
        j = find(phi-phi(idx) > pi/2, 1, 'first');
        k = find(phi-phi(idx) > -pi/2, 1, 'first');
        slope = -1;
    end
    Qg = f(idx)/abs(f(j)-f(k));
    model = @(p) phase_model(p, f, data, slope);
    pmin = fminsearch(model, [phi(idx), Qg, f(idx)]);
    fit = pmin(1) + 2*slope*atan(2*pmin(2)*(1 - f/pmin(3)));
    f0 = pmin(3); 
    Q = pmin(2);
    theta = pmin(1);
end
    
function [R, xc, yc] = fit_circle(x,y)
    %Fit the points x,y to a circle using algebra! See [2]    
    assert(length(x) == length(y), 'X and Y coordinates of circle must have same number of points.');
    n = length(x);
    z = x.^2 + y.^2;
    Mxx = sum(x.^2); Mx = sum(x);
    Myy = sum(y.^2); My = sum(y);
    Mzz = sum(z.^2); Mz = sum(z);
    Mxy = sum(x.*y);
    Mxz = sum(x.*z);
    Myz = sum(y.*z);
    M = [[Mzz Mxz Myz Mz]; [Mxz Mxx Mxy Mx]; [Myz Mxy Myy My]; [Mz Mx My n]];
    B = [[0 0 0 -2]; [0 1 0 0]; [0 0 1 0]; [-2 0 0 0]];
    %just solve the generalized eigenvalue problem -- reasonable for
    %the size of data we care about
    [V,D] = eig(M, B);
    D(D<eps) = NaN;
    [~,idx] = min(diag(D));
    ev = V(:,idx);
    xc = -ev(2)/2/ev(1);
    yc = -ev(3)/2/ev(1);
    R = sqrt(ev(2)^2 + ev(3)^2 - 4*ev(1)*ev(4))/2/abs(ev(1));
end
