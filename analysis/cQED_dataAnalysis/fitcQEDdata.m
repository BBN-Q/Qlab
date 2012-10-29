%%
clear all
close all

%% Load Data

fprintf('Loading Data\n')

if exist('fitCavityData_loadedData.mat','file') == 0
    Data_set_NA2 = parseDataFile_TO('W:\datafiles\Dummy_data_20100517T154526.out');
else
    load fitCavityData_loadedData.mat Data_set_NA2
end

fprintf('Done Loading Data\n')

%% Process NA data

real_Data_NA2 = Data_set_NA2.Data(1:2:end,:);
imag_Data_NA2 = Data_set_NA2.Data(2:2:end,:);
Data_set_NA2.mean_Data = real_Data_NA2.^2+imag_Data_NA2.^2;

freq_min   = Data_set_NA2.CFG.ExpParams.meas_resp.sweep_center.end - Data_set_NA2.CFG.ExpParams.meas_resp.sweep_span.end/2;
freq_max   = Data_set_NA2.CFG.ExpParams.meas_resp.sweep_center.end + Data_set_NA2.CFG.ExpParams.meas_resp.sweep_span.end/2;
freq_steps = Data_set_NA2.CFG.InitParams.pna.ordered.sweep_points;

v0_min   = Data_set_NA2.CFG.ExpParams.v1_pulse.offset.start;
v0_max   = Data_set_NA2.CFG.ExpParams.v1_pulse.offset.end;
v0_steps = Data_set_NA2.CFG.LoopParams.v0_offset.steps;

Data_set_NA2.PlotRanges.LO_RF_freq_range = linspace(freq_min,freq_max,freq_steps);
Data_set_NA2.PlotRanges.v0_offset_range  = linspace(v0_min,v0_max,v0_steps);

min_data_NA2 = min(Data_set_NA2.mean_Data);
[min_index_NA2_row min_index_NA2_column] = find(Data_set_NA2.mean_Data == repmat(min_data_NA2,[size(Data_set_NA2.mean_Data,1),1]));

Frequency_NA2 = 1e-9*Data_set_NA2.PlotRanges.LO_RF_freq_range(min_index_NA2_row);


%% Parameters

params_guess(1)        = 6.639606868178939e-007;
params_guess(2)        = 9.927538687275856e-015;
params_guess(3)        = 0.372479818538268;
params_guess(4)        = 12.498031204912369; %ratio of C_shunt to C_josephson, dimensionless
params_guess(5)        = 3.317486728524720e+007;%27.6427e6; % Hz
params_guess(6)        = 1.035590357695677e+010; % Hz
params_guess(7)        = -1.0395; %Phi_min in flux quanta
params_guess(8)        =  0.8684; %Phi_min in flux quanta

SimParameters.phi_min           = -3; % min value for qubit potential
SimParameters.phi_max           = 3;  % max "
SimParameters.LatticePoints     = 151;
SimParameters.numPhiSteps       = 50;
SimParameters.numQubitLevels    = 3;
SimParameters.maxPhotonNumber   = 1;

Constants.hbar          = 1.054e-34; % J*s
Constants.Phi0          = 2.068e-15; % Wb

%% unrestricted fit
residue = @(params) calculateResidue_cQEDsim(params,Frequency_NA2,SimParameters,Constants);
search_options = optimset('Display','iter','MaxIter',100);
params_min = fminsearch(residue,params_guess,search_options);

fitParameters.Ic        = params_min(1);
fitParameters.Cq        = params_min(2);
fitParameters.alpha     = params_min(3);
fitParameters.CsdCj     = params_min(4); %ratio of C_shunt to C_josephson, dimensionless
fitParameters.g         = params_min(5); % Hz
fitParameters.f_r       = params_min(6); % Hz

SimParameters.Phi_min   = params_min(7); %in units of Phi0
SimParameters.Phi_max   = params_min(8); %in units of Phi0

%% restricted fit, qubit parameters are set, only g and omega_r are varied
% residue = @(params) calculateResidue_cQEDsim([params_guess(1:4), params(1:4)],Frequency_NA2,SimParameters,Constants);
% search_options = optimset('Display','iter','MaxIter',100);
% params_min = fminsearch(residue,params_guess(5:8),search_options);
% 
% fitParameters.Ic        = params_guess(1);
% fitParameters.Cq        = params_guess(2);
% fitParameters.alpha     = params_guess(3);
% fitParameters.CsdCj     = params_guess(4); %ratio of C_shunt to C_josephson, dimensionless
% fitParameters.g         = params_min(1); % Hz
% fitParameters.f_r       = params_min(2); % Hz
% 
% SimParameters.Phi_min   = params_min(3); %in units of Phi0
% SimParameters.Phi_max   = params_min(4); %in units of Phi0

%% Simulate JC Hamiltonian

fprintf('Starting Simulation\n')
output = simulateCQEDqubit(fitParameters,SimParameters,Constants);
fprintf('Finished with Simulation\n')

%% Calculate flux range

x1 = Data_set_NA2.PlotRanges.v0_offset_range(1);
x2 = Data_set_NA2.PlotRanges.v0_offset_range(end);
y1 = SimParameters.Phi_min;
y2 = SimParameters.Phi_max;

Phi0_V_NA_new   = (x2-x1)/(y2-y1); % conversion factor
Phi0d2_V_NA_new = x1 - Phi0_V_NA_new*(y1-0.5);
Phi_NA2       = (Data_set_NA2.PlotRanges.v0_offset_range-Phi0d2_V_NA_new)/Phi0_V_NA_new + 0.5;

fprintf('Phi0ds_V = %.6f\n',Phi0d2_V_NA_new)
fprintf('Phi0_V   = %.6f\n',Phi0_V_NA_new)

%% Plot Data

df = 4e-3;

figure
plot(output.Phi_vector/Constants.Phi0,1e-9*output.JCFrequencies(1:2,:),'linewidth',3,'marker','.','markersize',20)
hold on
plot(Phi_NA2,Frequency_NA2,'.','markersize',24,'color','k')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

ylim([1e-9*fitParameters.f_r-df, 1e-9*fitParameters.f_r+df])
