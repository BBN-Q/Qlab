%%
clear all
close all

%% Load Data

fprintf('Loading Data\n')

if exist('fitCavityData_loadedData.mat','file') == 0

    addpath('C:\Documents and Settings\wkelly\My Documents\SVN\qlab\ExpTree\HomodyneDetection\src\matlab\');
    addpath('C:\Documents and Settings\wkelly\My Documents\SVN\qlab\ExpTree\RunExp\cfg\');
    addpath('C:\Documents and Settings\wkelly\My Documents\DR_Data\Data\HomodyneData\data');

    Data_set1 = parseDataFile('HomodyneDetection_v1_20100525T132714.out',0);
    Data_set2 = parseDataFile('HomodyneDetection_v1_20100525T142946.out',0);
    Data_set3 = parseDataFile('HomodyneDetection_v1_20100525T181551.out',0);
    Data_set4 = parseDataFile('W:\datafiles\HomodyneDetection_v1_20100527T104923.out',0);
    Data_set5 = parseDataFile('W:\datafiles\HomodyneDetection_v1_20100526T154233.out',0);
    Data_set6 = parseDataFile('W:\datafiles\HomodyneDetection_v1_20100528T161710.out',0);
    
    addpath('C:\Documents and Settings\wkelly\My Documents\SVN\qlab\Resonator_fitting')
    Data_set_NA1 = parseDataFile_TO('W:\datafiles\Dummy_data_20100517T142153.out');
    Data_set_NA2 = parseDataFile_TO('W:\datafiles\Dummy_data_20100517T154526.out');
    
    QubitSpecData  = load('\\cbl2\sync\datafiles\spectro.mat');
    QubitSpecData2 = load('\\cbl2\sync\datafiles\spectro3.mat');

    save fitCavityData_loadedData.mat Data_set1 Data_set2 Data_set3 ...
        Data_set4 Data_set5 Data_set6 Data_set_NA1 Data_set_NA2 QubitSpecData QubitSpecData2

else
    load fitCavityData_loadedData.mat
end


fprintf('Done Loading Data\n')

%% convert voltage to flux

Phi0d2_V = 0.6282;% 0.6344;%  % location of Phi0/2 in Volts
Phi0_V   = 3.77887; % conversion factor

%%
min_data_1 = min(Data_set1.mean_Data);
[min_index_1_row min_index_1_column] = find(Data_set1.mean_Data == repmat(min_data_1,[size(Data_set1.mean_Data,1),1]));

Frequency_1 = Data_set1.PlotRanges.LO_RF_freq_range(min_index_1_row);
Phi_1       = (Data_set1.PlotRanges.v0_offset_range-Phi0d2_V)/Phi0_V + 0.5;

min_data_2 = min(Data_set2.mean_Data);
[min_index_2_row min_index_2_column] = find(Data_set2.mean_Data == repmat(min_data_2,[size(Data_set2.mean_Data,1),1]));

Frequency_2 = Data_set2.PlotRanges.LO_RF_freq_range(min_index_2_row);
Phi_2       = (Data_set2.PlotRanges.v0_offset_range-Phi0d2_V)/Phi0_V + 0.5;

min_data_3 = min(Data_set3.mean_Data);
[min_index_3_row min_index_3_column] = find(Data_set3.mean_Data == repmat(min_data_3,[size(Data_set3.mean_Data,1),1]));

Frequency_3 = Data_set3.PlotRanges.LO_RF_freq_range(min_index_3_row);
Phi_3       = (Data_set3.PlotRanges.v0_offset_range-Phi0d2_V)/Phi0_V + 0.5;

Phi_3       = Phi_3(1:end-1);
Frequency_3 = Frequency_3(1:end-1);

%% Network analyzer data processing parameters

Phi0d2_V_NA = 0.284791;     % location of Phi0/2 in Volts
Phi0_V_NA   = Phi0_V/10; % conversion factor

min_cutoff      = 1e-6;

%% Process NA data

% 1

real_Data_NA1 = Data_set_NA1.Data(1:2:end,:);
imag_Data_NA1 = Data_set_NA1.Data(2:2:end,:);
Data_set_NA1.mean_Data = real_Data_NA1.^2+imag_Data_NA1.^2;

freq_min   = Data_set_NA1.CFG.ExpParams.meas_resp.sweep_center.end - Data_set_NA1.CFG.ExpParams.meas_resp.sweep_span.end/2;
freq_max   = Data_set_NA1.CFG.ExpParams.meas_resp.sweep_center.end + Data_set_NA1.CFG.ExpParams.meas_resp.sweep_span.end/2;
freq_steps = Data_set_NA1.CFG.InitParams.pna.ordered.sweep_points;

v0_min   = Data_set_NA1.CFG.ExpParams.v1_pulse.offset.start;
v0_max   = Data_set_NA1.CFG.ExpParams.v1_pulse.offset.end;
v0_steps = Data_set_NA1.CFG.LoopParams.v0_offset.steps;

Data_set_NA1.PlotRanges.LO_RF_freq_range = linspace(freq_min,freq_max,freq_steps);
Data_set_NA1.PlotRanges.v0_offset_range  = linspace(v0_min,v0_max,v0_steps);

min_data_NA1 = min(Data_set_NA1.mean_Data);
[min_index_NA1_row min_index_NA1_column] = find(Data_set_NA1.mean_Data == repmat(min_data_NA1,[size(Data_set_NA1.mean_Data,1),1]));

Frequency_NA1 = 1e-9*Data_set_NA1.PlotRanges.LO_RF_freq_range(min_index_NA1_row);
Phi_NA1       = (Data_set_NA1.PlotRanges.v0_offset_range-Phi0d2_V_NA)/Phi0_V_NA + 0.5;

Frequency_NA1 = Frequency_NA1(min_data_NA1 < min_cutoff);
Phi_NA1       = Phi_NA1(min_data_NA1 < min_cutoff);

% 2

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
Phi_NA2       = (Data_set_NA2.PlotRanges.v0_offset_range-Phi0d2_V_NA)/Phi0_V_NA + 0.5;

Frequency_NA2 = Frequency_NA2(min_data_NA2 < min_cutoff);
Phi_NA2       = Phi_NA2(min_data_NA2 < min_cutoff);

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

%% Parameters

fitParameters.Ic    = 6.639606868178939e-007;
fitParameters.Cq    = 9.927538687275856e-015;
fitParameters.alpha = 0.372479818538268;
fitParameters.CsdCj = 12.498031204912369;
fitParameters.g     = 3.317486728524720e+007;
fitParameters.f_r   = 1.035590357695677e+010;

SimParameters.phi_min           = -3; % min value for qubit potential
SimParameters.phi_max           =  3; % max "
SimParameters.LatticePoints     = 151;
SimParameters.Phi_min           = -1.2; %in units of Phi0
SimParameters.Phi_max           =  1.0; %in units of Phi0
SimParameters.numPhiSteps       = 300;
SimParameters.numQubitLevels    = 4;
SimParameters.maxPhotonNumber   = 2;

Constants.hbar          = 1.054e-34; % J*s
Constants.Phi0          = 2.068e-15; % Wb

%% Simulate JC Hamiltonian

fprintf('Starting Simulation\n')
output = simulateCQEDqubit(fitParameters,SimParameters,Constants);
fprintf('Finished with Simulation\n')

%% Plot Data

df = 4e-3;

figure
plot(output.Phi_vector/Constants.Phi0,1e-9*output.JCFrequencies(1:4,:),'linewidth',3)
hold on
plot(Phi_NA1,Frequency_NA1,'.','markersize',24,'color','r')
plot(Phi_NA2,Frequency_NA2,'.','markersize',24,'color','k')
plot([Phi_1,Phi_2],[Frequency_1,Frequency_2],'.','markersize',24)
plot(Phi_3,Frequency_3,'.','markersize',24,'color',[0 0.5 0])
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

figure1 = figure;
axes1 = axes('Parent',figure1);
hold on
plot(output.Phi_vector/Constants.Phi0,1e-9*output.JCFrequencies(1:2,:),'linewidth',3,'DisplayName',{'Theory';'Theory'})
plot(Phi_NA1,Frequency_NA1,'.','markersize',24,'color','r','DisplayName','Cavity Transmission')
plot(Phi_NA2,Frequency_NA2,'.','markersize',24,'color','k','DisplayName','Cavity Transmission')
plot([Phi_1,Phi_2],[Frequency_1,Frequency_2],'.','markersize',24,'DisplayName','Homodyne')
plot(Phi_3,Frequency_3,'.','markersize',24,'color',[0 0.5 0],'DisplayName','Homodyne')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

xlim([SimParameters.Phi_min SimParameters.Phi_max])
ylim([1e-9*fitParameters.f_r-df, 1e-9*fitParameters.f_r+df])

% h_legend = legend(axes1,'show');
% set(h_legend,'FontSize',20)

%%

Phi_start = 2*(min(Phi_Q1(1),Phi_Q2(1))-0.5)+0.5;
Phi_end   = 2*(max(Phi_Q1(end),Phi_Q2(end))-0.5)+0.5;
Phi_points = 100;

SimParameters.Phi_min           = Phi_start; %in units of Phi0
SimParameters.Phi_max           = Phi_end; %in units of Phi0
SimParameters.numPhiSteps       = Phi_points;

output = simulateCQEDqubit(fitParameters,SimParameters,Constants);
Phi_vector = linspace(Phi_start,Phi_end,Phi_points);
qubitFrequencies = output.qubitEnergies_interp(Phi_vector*Constants.Phi0)/2/pi/Constants.hbar*1e-9;
qubit01Transition = qubitFrequencies(1,:);
qubit02Transition = sum(qubitFrequencies(1:2,:))/2;
qubit12Transition = qubitFrequencies(2,:);

figure2 = figure;
axes2 = axes('Parent',figure2);
hold on
plot(Phi_vector,qubit01Transition,'linewidth',3,'DisplayName','\omega_{01} theory')
plot(Phi_vector,qubit02Transition,'linewidth',3,'color',[0 0.5 0],'DisplayName','\omega_{02} theory')
plot(Phi_vector,qubit12Transition,'linewidth',3,'color','r','DisplayName','\omega_{12} theory')
plot(Phi_Q1,Frequency_Q1,'.','markersize',24,'DisplayName','\omega_{01} exp')
plot(Phi_Q2,Frequency_Q2,'.','markersize',24,'color',[0 0.5 0],'DisplayName','\omega_{02} exp')
plot(Phi_Q3,Frequency_Q3,'.','markersize',24,'color','r','DisplayName','\omega_{12} exp')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

h_legend = legend(axes2,'show');
set(h_legend,'FontSize',20)
axis tight

%%

Phi_Q4_range  = (Data_set4.PlotRanges.v0_offset_range - Phi0d2_V)/Phi0_V+0.5;
Freq_Q4_range = Data_set4.PlotRanges.qubit_frequency_range;
Data_Q4_bg    = Data_set4.mean_Data - repmat(Data_set4.mean_Data(:,end),[1 size(Data_set4.mean_Data,2)]);

figure3 = figure;
axes3 = axes('Parent',figure3);
imagesc(Phi_Q4_range,Freq_Q4_range,Data_Q4_bg)
set(gca,'Ydir','normal')
hold on
plot(Phi_vector,qubit01Transition,'linewidth',3,'DisplayName','\omega_{01} theory')
plot(Phi_vector,qubit02Transition,'linewidth',3,'color',[0 0.5 0],'DisplayName','\omega_{02} theory')
plot(Phi_vector,qubit12Transition,'linewidth',3,'color','r','DisplayName','\omega_{12} theory')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

h_legend = legend(axes3,'show');
set(h_legend,'FontSize',20,'location','bestoutside')
axis([Phi_Q4_range(1), Phi_Q4_range(end), Freq_Q4_range(1), Freq_Q4_range(end)])

%%

Phi_Q5_range  = (Data_set5.PlotRanges.v0_offset_range - Phi0d2_V)/Phi0_V+0.5;
Freq_Q5_range = Data_set5.PlotRanges.qubit_frequency_range;
Data_Q5_bg    = Data_set5.mean_Data - repmat(mean(Data_set5.mean_Data.').',[1 size(Data_set5.mean_Data,2)]);
Freq_min = 7.2;
Freq_max = max(Freq_Q5_range);


figure3 = figure;
axes3 = axes('Parent',figure3);
imagesc(Phi_Q5_range,Freq_Q5_range,Data_Q5_bg)
set(gca,'Ydir','normal')
hold on
plot(Phi_vector,qubit01Transition,'linewidth',3,'DisplayName','\omega_{01} theory')
plot(Phi_vector,qubit02Transition,'linewidth',3,'color',[0 0.5 0],'DisplayName','\omega_{02} theory')
plot(Phi_vector,qubit12Transition,'linewidth',3,'color','r','DisplayName','\omega_{12} theory')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

h_legend = legend(axes3,'show');
set(h_legend,'FontSize',20,'location','bestoutside')
axis([Phi_Q5_range(1), Phi_Q5_range(end), Freq_min, Freq_max])

%%

Phi_Q6_range  = (Data_set6.PlotRanges.v0_offset_range - Phi0d2_V)/Phi0_V+0.5;
Freq_Q6_range = Data_set6.PlotRanges.qubit_frequency_range;
Data_Q6_bg    = Data_set6.mean_Data;
Freq_min = 7.2;
Freq_max = max(Freq_Q6_range);


figure3 = figure;
axes3 = axes('Parent',figure3);
imagesc(Phi_Q6_range,Freq_Q6_range,Data_Q6_bg)
set(gca,'Ydir','normal')
hold on
plot(Phi_vector,qubit01Transition,'linewidth',3,'DisplayName','\omega_{01} theory')
plot(Phi_vector,qubit02Transition,'linewidth',3,'color',[0 0.5 0],'DisplayName','\omega_{02} theory')
plot(Phi_vector,qubit12Transition,'linewidth',3,'color','r','DisplayName','\omega_{12} theory')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

h_legend = legend(axes3,'show');
set(h_legend,'FontSize',20,'location','bestoutside')
axis([Phi_Q6_range(1), Phi_Q6_range(end), Freq_min, Freq_max])