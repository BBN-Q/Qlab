clear all
close all
%%

load fitCavityData_loadedData.mat

%% convert voltage to flux

Phi0d2_V = 0.6282; %0.6344;  % location of Phi0/2 in Volts
Phi0_V   = 3.77914; % conversion factor

%% Qubit Spec data
Q1_start = 1;
Q1_end   = 13;
Q2_start = 1;
Q2_end   = 16;

Frequency_Q1 = QubitSpecData.freq2(Q1_start:Q1_end);
Phi_Q1 = (QubitSpecData.volt2(Q1_start:Q1_end)-Phi0d2_V)/Phi0_V + 0.5;

Frequency_Q2 = QubitSpecData.freq(Q2_start:Q2_end);
Phi_Q2 = (QubitSpecData.volt(Q2_start:Q2_end)-Phi0d2_V)/Phi0_V + 0.5;

%%

Phi_start = 2*(min(Phi_Q1(1),Phi_Q2(1))-0.5)+0.5;
Phi_end   = 2*(max(Phi_Q1(end),Phi_Q2(end))-0.5)+0.5;
Phi_points = 100;

fitParameters.Ic    = 4.881245449231247e-007;
fitParameters.Cq    = 8.866359692454990e-015;
fitParameters.alpha = 0.368;%0.361090940732665;
fitParameters.CsdCj = 10.783168825881376;
fitParameters.g     = 3.267822895023873e+007;
fitParameters.f_r   = 1.035589445187087e+010;
      
SimParameters.phi_min           = -3; % min value for qubit potential
SimParameters.phi_max           = 3;  % max "
SimParameters.LatticePoints     = 151;
SimParameters.Phi_min           = Phi_start; %in units of Phi0
SimParameters.Phi_max           = Phi_end; %in units of Phi0
SimParameters.numPhiSteps       = Phi_points;
SimParameters.numQubitLevels    = 3;
SimParameters.maxPhotonNumber   = 1;

Constants.hbar          = 1.054e-34; % J*s
Constants.Phi0          = 2.068e-15; % Wb

output = simulateCQEDqubit(fitParameters,SimParameters,Constants);

Phi_vector = linspace(Phi_start,Phi_end,Phi_points);
qubitFrequencies = output.qubitEnergies_interp(Phi_vector*Constants.Phi0)/2/pi/Constants.hbar*1e-9;
qubit01Transition = qubitFrequencies(1,:);
qubit02Transition = sum(qubitFrequencies(1:2,:))/2;

figure
hold on
plot(Phi_vector,qubit01Transition,'linewidth',3)
plot(Phi_vector,qubit02Transition,'linewidth',3,'color',[0 0.5 0])
plot(Phi_Q1,Frequency_Q1,'.','markersize',24)
plot(Phi_Q2,Frequency_Q2,'.','markersize',24,'color',[0 0.5 0])
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')
