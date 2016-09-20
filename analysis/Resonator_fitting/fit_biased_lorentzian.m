% Author/Date: Guilhem Ribeill, 
%
% Copyright 2016 Raytheon BBN Technologies

function [fit_params, fit_vars] = fit_biased_lorentzian(freq, data, varargin)
% FIT_BIASED_LORENTZIAN Fit frequency-amplitude data to a skewed
% lorentizan. Returns parameters of fit and variance of parameters
%
%   [FIT_PARAMS, FIT_ERRORS] = FIT_BIASED_LORENTZIAN(FREQ, DATA) fits
%   data to a biased lorentzian of the form
%   f(x) = a / ((x - b)^2 + (c / 2)^2) + d*(x - b) + e
%   For two-dimensional data fits a lorentzian to each slice of data whose 
%   dimension matches that of frequency. For square matricies, a lorentzian
%   is fit to each column of data. 
%   Optional string-value parameters:
%       - 'MaxIter': Maximum number of fminsearch iterations. Default 2000.
%       - 'Plot': Plot result of fit
persistent figHandles;
if isempty(figHandles)
        figHandles = struct();
end
parser = inputParser;
defaultDim = 1;
defaultMaxIter = 2000;
addRequired(parser, 'freq', @isnumeric);
addRequired(parser, 'data', @isnumeric);
addOptional(parser, 'dims', defaultDim, @isnumeric);
addParameter(parser, 'MaxIter', defaultMaxIter, @isnumeric);
addParameter(parser, 'Plot', 0);
parse(parser, freq, data, varargin{:});
dims = parser.Results.dims;

%validate inputs
freq = freq(:);
if isvector(data)
    data = data(:);
    N = length(data); M = 1;
    if length(data) ~= length(freq)
        error('Data and frequency dimensions do not match');
    end
elseif ~ismatrix(data)
    error('Data has too many dimensions. I don''t know how to proceed.')
else
    [N, M] = size(data);
    if N ~= length(freq) && M ~= length(freq)
        error('Data dimensions do not match frequency vector dimensions.')
    end
    if strmatch('dims', parser.UsingDefaults)
        if M == length(freq)
            data = data';
            t = M; M = N; N = t;
        end
    else
        if dims == 2
            data = data';
            t = M; M = N; N = t;
        end
    end
end

options = optimset('MaxIter', parser.Results.MaxIter);

fit_params = zeros(M, 5);
fit_vars = zeros(M, 5);
ssemin = zeros(M,1);

for idx = 1:M  
    p0 = initial_guess(freq, data(:,idx));
    model = @(p)bias_lorentz_model(p, freq, data(:,idx));
    [p, ssemin(idx)] = fminsearch(model, p0, options);
    fit_params(idx, :) = p;
    fit_vars(idx, :) = lorentz_variance(p, freq, ssemin(idx))';
end

if parser.Results.Plot 
    
    if M == 1
        ffit = bias_lorentz(fit_params(1,:), freq);
        [~, pband] = lorentz_variance(fit_params(1,:), freq, ssemin(1));
        
        if ~isfield(figHandles, 'fit_plot') || ~ishandle(figHandles.('fit_plot'))
            figHandles.('fit_plot') = figure('Name', 'Lorentzian Fit');
        else
            figure(figHandles.('fit_plot')); clf;
        end
        hold on;
        plot(freq, data, '.', 'MarkerSize', 15);
        plot(freq, ffit, 'r-', 'LineWidth', 2);
        plot(freq, ffit+1.96*pband, 'r--', 'LineWidth', 2);
        plot(freq, ffit-1.96*pband, 'r--', 'LineWidth', 2);
        grid on;
        xlabel('Frequency', 'FontSize', 15);
        ylabel('Amplitude', 'FontSize', 15);
        title(sprintf('Biased Lorentzian Fit, f_0 = %.3f, FWHM = %.3f', fit_params(2), 2*fit_params(3)), 'FontSize', 12);
        legend('Data', 'Fit', '95% C.I.');
        set(gca, 'FontSize', 14);
        
    else
        figure();
        imagesc(freq, 1:M, data');
        
        fit = zeros(size(data));
        for m=1:M
            fit(:,m) = bias_lorentz(fit_params(m,:), freq);
        end
        
        if ~isfield(figHandles, 'fit_plot') || ~ishandle(figHandles.('fit_plot'))
            figHandles.('fit_plot') = figure('Name', '2D Data Lorentzian Fit');
        else
            figure(figHandles.('fit_plot')); clf;
        end
        subplot(1,2,1);
        imagesc(freq, 1:M, data'); axis square;
        xlabel('Frequency', 'FontSize', 15);
        title('Data', 'FontSize', 12);
        set(gca, 'FontSize', 14);
        subplot(1,2,2);
        imagesc(freq, 1:M, fit'); axis square;
        xlabel('Frequency', 'FontSize', 15);
        title('Fit', 'FontSize', 12);
        set(gca, 'FontSize', 14);
        
        if ~isfield(figHandles, 'fit_params') || ~ishandle(figHandles.('fit_params'))
            figHandles.('fit_params') = figure('Name', 'Fit Parameters');
        else
            figure(figHandles.('fit_params')); clf;
        end
        subplot(2,1,1);
        errorbar(1:M, fit_params(:,2), 1.96*sqrt(fit_vars(:,2)), '.', 'MarkerSize', 15, 'LineWidth', 2);
        ylabel('f_0', 'FontSize', 15); set(gca, 'FontSize', 14); grid on;
        subplot(2,1,2);
        errorbar(1:M, fit_params(:,3), 1.96*sqrt(fit_vars(:,3)), '.', 'MarkerSize', 15, 'LineWidth', 2);
        ylabel('FWHM', 'FontSize', 15); set(gca, 'FontSize', 14); grid on;
        xlabel('Frequency');
        
        
    end
        
end

end

function y = bias_lorentz(params, x)
    a = params(1);
    b = params(2);
    c = params(3);
    d = params(4);
    e = params(5);
    y = a ./ ((x - b).^2 + (c/2)^2) + d*(x - b) + e;
end

function [sse, fitted] = bias_lorentz_model(params, x, data)
% Returns sum of squared errors and ci's for fminsearchbnd
    fitted = bias_lorentz(params, x);
    errorVec = fitted - data;
    sse = sum(errorVec.^2);

end

function [sigmasq, prediction_band] = lorentz_variance(params, x, sse)
    %Returns the variance of estimated parameters
    n = length(x);
    q = length(params);
    J = zeros(n, q);
    J(:,1) = 1./((x-params(2)).^2 + (params(3)/2).^2);
    J(:,2) = 2*params(1)*(x - params(2))./((x-params(2)).^2 + (params(3)/2).^2).^2 - params(4);
    J(:,3) = -params(1)*params(3)./((x-params(2)).^2 + (params(3)/2).^2).^2;
    J(:,4) = (x - params(2));
    J(:,5) = ones(n,1);
    cov = (J'*J).^-1;
    sigmasq = sse/(n - q)*diag(cov);
    prediction_band = zeros(n,1);
    for idx=1:n
        prediction_band = sqrt(sse/(n-q)*abs(J(idx,:)*cov*J(idx,:)'));
    end
end
    
function params = initial_guess(x, data)
%Returns an initial guess for lorentzian
%f(x) = a / ((x-b)^2 - (c/2)^2) + d*(x-b) + e
    if max(data) - median(data) <= min(data) - median(data)
        e = min(data);
        [~, idx] = max(data);
        disp('Normal')
    else
        e = max(data);
        [~, idx] = min(data);
        disp('Inverted')
    end
    b = x(idx);
    half = (median(data) + data(idx)) / 2;
    idx_l = find(data > half, 1, 'first');
    idx_r = find(data > half, 1, 'last');
    c = abs(x(idx_l) - x(idx_r));
    a = c^2*(max(data)-min(data))/4;
    d = (data(end) - data(1))/(x(end) - x(1));
    params = [a, b, c, 0., e];
end
    
    
    
