clear all
close all
%%

load fitCavityData_loadedData.mat

%% convert voltage to flux

Phi0d2_V   = 0.6282; %0.6344;  % location of Phi0/2 in Volts
Phi0_V   = 3.77914; % conversion factor

%% Qubit Spec data
Q1_start = 1;
Q1_end   = 13;
Q2_start = 1;
Q2_end   = 16;
Q3_start = 1;
Q3_end   = 6;

Frequency_Q1 = QubitSpecData.freq2(Q1_start:Q1_end);
Phi_Q1 = (QubitSpecData.volt2(Q1_start:Q1_end)-Phi0d2_V)/Phi0_V + 0.5;

Frequency_Q2 = QubitSpecData.freq(Q2_start:Q2_end);
Phi_Q2 = (QubitSpecData.volt(Q2_start:Q2_end)-Phi0d2_V)/Phi0_V + 0.5;

Frequency_Q3 = QubitSpecData2.freq3(Q3_start:Q3_end);
Phi_Q3 = (QubitSpecData2.volt3(Q3_start:Q3_end)-Phi0d2_V)/Phi0_V + 0.5;

%%


params_guess(1)    = 4.881245449231247e-007; % Ic
params_guess(2)    = 8.866359692454990e-015; % C_q
params_guess(3)    = 0.368; % alpha
params_guess(4)    = 10.783168825881376; %CsdCj
      
SimParameters.phi_min           = -3; % min value for qubit potential
SimParameters.phi_max           = 3;  % max "
SimParameters.LatticePoints     = 151;
SimParameters.numQubitLevels    = 3;

Constants.hbar          = 1.054e-34; % J*s
Constants.Phi0          = 2.068e-15; % Wb

%%

% residue = @(params) calculateResidue_qubitSpec(params,{Phi_Q1,Phi_Q2},{Frequency_Q1,Frequency_Q2},SimParameters,Constants,{'01','02'});
% search_options = optimset('Display','iter','MaxIter',200);
% params_min = fminsearch(residue,params_guess,search_options);

residue = @(params) calculateResidue_qubitSpec(params,{Phi_Q2,Phi_Q3},{Frequency_Q2,Frequency_Q3},SimParameters,Constants,{'02','12'});
search_options = optimset('Display','iter','MaxIter',200);
params_min = fminsearch(residue,params_guess,search_options);

%%

Phi_start = 2*(min(Phi_Q1(1),Phi_Q2(1))-0.5)+0.5;
Phi_end   = 2*(max(Phi_Q1(end),Phi_Q2(end))-0.5)+0.5;
Phi_points = 100;

fitParameters.Ic    = params_min(1);
fitParameters.Cq    = params_min(2);
fitParameters.alpha = params_min(3);
fitParameters.CsdCj = params_min(4);
fitParameters.g     = 3.317486728524720e+007;
fitParameters.f_r   = 1.035590357695677e+010;
      
SimParameters.phi_min           = -3; % min value for qubit potential
SimParameters.phi_max           =  3; % max "
SimParameters.LatticePoints     = 151;
SimParameters.Phi_min           = Phi_start; %in units of Phi0
SimParameters.Phi_max           = Phi_end; %in units of Phi0
SimParameters.numPhiSteps       = Phi_points;
SimParameters.numQubitLevels    = 3;
SimParameters.maxPhotonNumber   = 1;

fprintf('Starting Simulation\n')
output = simulateCQEDqubit(fitParameters,SimParameters,Constants);
fprintf('Finished with Simulation\n')

%%

Phi_vector = output.Phi_vector/Constants.Phi0;
qubitFrequencies = output.qubitEnergies_interp(Phi_vector*Constants.Phi0)/2/pi/Constants.hbar*1e-9;
qubit01Transition = qubitFrequencies(1,:);
qubit02Transition = sum(qubitFrequencies(1:2,:))/2;
qubit12Transition = qubitFrequencies(2,:);

%%

figure1 = figure;
axes1 = axes('Parent',figure1);
hold on
plot(Phi_vector,qubit01Transition,'linewidth',3,'DisplayName','\omega_{01} theory')
plot(Phi_vector,qubit02Transition,'linewidth',3,'color',[0 0.5 0],'DisplayName','\omega_{02}/2 theory')
plot(Phi_vector,qubit12Transition,'linewidth',3,'color','r','DisplayName','\omega_{12} theory')
plot(Phi_Q1,Frequency_Q1,'.','markersize',24,'DisplayName','\omega_{01} exp')
plot(Phi_Q2,Frequency_Q2,'.','markersize',24,'color',[0 0.5 0],'DisplayName','\omega_{02}/2 exp')
plot(Phi_Q3,Frequency_Q3,'.','markersize',24,'color','r','DisplayName','\omega_{12} exp')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

h_legend = legend(axes1,'show');
set(h_legend,'FontSize',20)
