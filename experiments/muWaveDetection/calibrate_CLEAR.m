function [eps1_0, eps2_0] = calibrate_CLEAR(qubit, meas_qubit, kappa, chi, t_empty, varargin)
%search for the optimum 2-step CLEAR pulse, starting from an initial guess

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

%Arguments:
%qubit
%meas_qubit: auxiliary qubit used for CLEAR pulse
%kappa: cavity linewidth (1/us)
%chi: half of the dispershive shift (1/us)
%t_empty: time allowed to deplete the cavity (us)
%note: kappa, chi are angular frequencies (1/time)

parser = inputParser;

addOptional(parser, 'ramsey_stop', 2, @isnumeric);
addOptional(parser, 'npoints', 101, @isnumeric);
addOptional(parser, 'ramsey_freq', 2*pi*4, @isnumeric);
addOptional(parser, 'delay', 1.5, @isnumeric);
addOptional(parser, 'alpha', 0.4, @isnumeric); %rescaling factor
addOptional(parser, 'T1factor', exp(-1/30), @isnumeric); %T1 decay before Ramsey
addOptional(parser, 'T2', 30, @isnumeric); %T2*
addOptional(parser, 'nsteps', 11, @isnumeric); %calibration steps (/ sweep)
addOptional(parser, 'calsteps', [1 1 1]); %choose ranges for calibration steps: 1: +-100%; 0: skip step

%Start from theoretical values, unless given as inputs
eps1_th = (1 - 2*exp(kappa*t_empty/4)*cos(chi*t_empty/2))/(1+exp(kappa*t_empty/2)-2*exp(kappa*t_empty/4)*cos(chi*t_empty/2));
eps2_th = 1/(1+exp(kappa*t_empty/2)-2*exp(kappa*t_empty/4)*cos(chi*t_empty/2));

addOptional(parser, 'eps1', eps1_th, @isnumeric);
addOptional(parser, 'eps2', eps2_th, @isnumeric);
parse(parser, varargin{:});
ramsey_stop = parser.Results.ramsey_stop;
npoints = parser.Results.npoints;
ramsey_freq = parser.Results.ramsey_freq;
delay = parser.Results.delay;
alpha = parser.Results.alpha;
T1factor = parser.Results.T1factor;
T2 = parser.Results.T2;
nsteps = parser.Results.nsteps;
calsteps = parser.Results.calsteps;
eps1_0 = parser.Results.eps1;
eps2_0 = parser.Results.eps2;

xpoints = linspace(0, ramsey_stop, npoints);
n0vec = zeros(nsteps,1);
n1vec = zeros(nsteps,1);

if ~isfield(figHandles, 'CLEAR') || ~ishandle(figHandles.('CLEAR'))
    figHandles.('CLEAR') = figure('Name', 'CLEAR','Visible','Off');
else
    figure(figHandles.('CLEAR'),'Visible','Off'); clf()
end
ColOrd = get(gca,'ColorOrder');

%Sweep amplitude of CLEAR steps, keeping the ration eps2/eps1 constant
for ct = 1:3
    if ~calsteps(ct)
        break
    end
    fprintf('Calibration step %d\n', ct);
    xpts = linspace(1-calsteps(ct), 1+calsteps(ct), nsteps);
    for k=1:nsteps
        switch ct
            case 1
                eps1 = xpts(k)*eps1_0;
                eps2 = xpts(k)*eps2_0;
            case 2
                eps1 = xpts(k)*eps1_0;
                eps2 = eps2_0;
            case 3
                eps1 = eps1_0;
                eps2 = xpts(k)*eps2_0;
        end
        %Generate the sequence
        CLEARCalSequence(qubit, meas_qubit, ramsey_stop, npoints, ramsey_freq, delay, eps1*alpha, eps2*alpha, t_empty/2, 0)
        %Run the sequence
        ExpScripter2('CLEAR_cal', 'CLEARCal\CLEARCal', 'lockSegments') %temporary kludge to deal with multiple measurements on different logical channels
        %Fit photon number
        data = load_data('latest');
        caldata = real(cal_scale(data.data));
        n0vec(k) = fit_photon_number(xpoints, caldata, [kappa, ramsey_freq, 2*chi, T2, T1factor, 0]);
        
        %Repeat for qubit in |1>
        CLEARCalSequence(qubit, meas_qubit, ramsey_stop, npoints, ramsey_freq, delay, eps1*alpha, eps2*alpha, t_empty/2, 0)
        ExpScripter2('CLEAR_cal', 'CLEARCal\CLEARCal', 'lockSegments')
        data = load_data('latest');
        caldata = real(cal_scale(data.data));
        n1vec(k) = fit_photon_number(xpoints, caldata, [kappa, ramsey_freq, 2*chi, T2, T1factor, 1]);
        figure(figHandles.('CLEAR')); 
        set(gcf,'position',[550,300,1000,350])
        subplot(1,3,ct)
        hold off
        plot(xpts(1:k), n0vec(1:k), '.-','markerSize', 10, 'Color', ColOrd(1,:));
        hold on;
        plot(xpts(1:k), n1vec(1:k), '.-','markerSize', 10, 'Color', ColOrd(2,:));
        title(sprintf('CLEAR calibration, step %d', ct))
        switch ct
            case 1
                sweep_label = '\epsilon_1, \epsilon_2';
            case 2
                sweep_label = '\epsilon_1';
            case 3
                sweep_label = '\epsilon_2';
        end
        xlabel(['Scaling factor ' sweep_label])
        ylabel('Photon number n_0')
        drawnow()
    end
    %Fit for minimum photon number
    [~,x0] = min(n0vec);
    [~,x1] = min(n1vec);
    quadf = inline('p(1)*(tdata - p(2)).^2 + p(3)','p','tdata');
    xfine = linspace(0,2,1001);
    p0 = [1 x0 0];
    p1 = [1 x1 0];
    [beta0,~,~] = nlinfit(xpts', n0vec, quadf, p0);
    [~, fit_x0] = min(quadf(beta0, xfine));
    figure(figHandles.('CLEAR'));
    hold on;
    plot(xfine, quadf(beta0, xfine), '--', 'Color', ColOrd(1,:));
    [beta1,~,~] = nlinfit(xpts', n1vec, quadf, p1);
    [~, fit_x1] = min(quadf(beta1, xfine));
    hold on;
    plot(xfine, quadf(beta1, xfine), '--', 'Color', ColOrd(2,:));
    legend('0', '1', 'fit, 0', 'fit, 1')
    ylim([-0.2,3])
    opt_scaling = (xfine(fit_x0)+xfine(fit_x1))/2;
    fprintf('Optimum scaling factor: %.2f\n', opt_scaling);
    
    %update best eps1, eps2
    eps1_0 = eps1_0*opt_scaling;
    eps2_0 = eps2_0*opt_scaling;
    str1 = '$$ \epsilon_1 $$';
    str2 = '$$ \epsilon_2 $$';
    %eps1_s = num2str(eps1_0)
    text(0, 0.2, [str1 ' = ' num2str(eps1_0,3) '; ' str2 ' = ' num2str(eps2_0,3)],'HorizontalAlignment', 'left', 'VerticalAlignment', 'top','Interpreter','latex');
end
%TODO: update pulse shape. Make these parameters?
end


