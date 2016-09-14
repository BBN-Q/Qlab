function [x0vec, dx0vec] = fit_DRAG_cal(obj, data, DRAG_list, pulse_list)

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

DRAG_list = DRAG_list(:);
pulse_list = pulse_list(:);

num_DRAG = length(DRAG_list); %number of DRAG parameters for each pulse number
num_seqs = length(pulse_list); 
caldata=real(cal_scale(data)); %.data));
reshaped_data = reshape(caldata,num_DRAG,size(caldata,1)/num_DRAG);
x0vec = zeros(num_seqs - 1,1);
dx0vec = zeros(num_seqs - 1,1);
ct = 1;

ColOrd = get(gca,'ColorOrder');

%first fit sine to lowest n, for the full range
data_n = reshaped_data(:, ct);
[~, maxloc_data_n] = max(data_n);
[~, minloc_data_n] = min(data_n);
T0 = 2*(DRAG_list(maxloc_data_n) - DRAG_list(minloc_data_n)); %rough estimate of period

sinf = inline('p(1) + p(2).*cos(2*pi*xpoints/p(3) + p(4))','p','xpoints');
p = [0, 1, T0, 0];
[beta,~,~] = nlinfit(DRAG_list, data_n, sinf, p);
xfine = linspace(min(DRAG_list), max(DRAG_list), 1001);
[~, fit_minloc] = min(sinf(beta, xfine));
x0 = xfine(fit_minloc); %first pass


if ~isfield(figHandles, 'DRAG') || ~ishandle(figHandles.('DRAG'))
    figHandles.('DRAG') = figure('Name', 'DRAG');
else
    figure(figHandles.('DRAG')); clf;
end
subplot(1,2,1)


fit_curve = sinf(beta, xfine);
plot(DRAG_list, data_n, '.-', 'Color', ColOrd(mod(ct,size(ColOrd,1))+1,:));
hold on
plot(xfine, fit_curve, '--', 'Color', ColOrd(mod(ct,size(ColOrd,1))+1,:));

for ct = 2:length(pulse_list)
    %quadratic fit for subsequent steps, narrower range
    data_n = reshaped_data(:, ct);
    quadf = inline('p(1)*(tdata - p(2)).^2 + p(3)','p','tdata');
    p = [1 x0 0];
    
    %recenter
    [~, closest_ind] = min(abs(DRAG_list - x0));
    fit_range = round(0.5*num_DRAG*pulse_list(1)/pulse_list(ct));
    curr_DRAG_list = DRAG_list(max(1,closest_ind - fit_range) : min(length(DRAG_list), closest_ind + fit_range));
    reduced_data_n = data_n(max(1,closest_ind - fit_range) : min(length(DRAG_list), closest_ind + fit_range));
    [beta,r,j] = nlinfit(curr_DRAG_list, reduced_data_n, quadf, p);
    xfine = linspace(min(curr_DRAG_list), max(curr_DRAG_list), 1001);
        
    if beta(1)<0
        error('Quadratic fit failed')
    end
    
    x0 = beta(2);
    x0vec(ct - 1) = x0;
    ci = nlparci(beta,r,j);
    dx0vec(ct - 1) = (ci(2,2)-ci(2,1))/2;
    
    fit_curve = quadf(beta, xfine);
    plot(DRAG_list, data_n, '.-', 'Color', ColOrd(mod(ct,size(ColOrd,1))+1,:));
    plot(xfine, fit_curve, '--', 'Color', ColOrd(mod(ct,size(ColOrd,1))+1,:));
end
xlabel('dragScaling')
ylabel('<Z>')
title('DRAG calibration')

subplot(1,2,2)
errorbar(pulse_list(2:end),x0vec,dx0vec,'.-','markerSize',10)
xlabel('Number of pseudoId')
ylabel('Fit dragScaling')
title('DRAG calibration')

end