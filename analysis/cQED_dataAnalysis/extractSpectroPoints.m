clear all
close all

%%

fprintf('Loading Data\n')
load fitCavityData_loadedData.mat
fprintf('Done Loading Data\n')

%% convert voltage to flux

Phi0d2_V   = 0.6282; %0.6344;  % location of Phi0/2 in Volts
Phi0_V   = 3.77914; % conversion factor

%%

Phi_Q6_range  = (Data_set6.PlotRanges.v0_offset_range - Phi0d2_V)/Phi0_V+0.5;
Freq_Q6_range = Data_set6.PlotRanges.qubit_frequency_range;
Data_Q6_bg    = Data_set6.mean_Data;

%%

Lorentzian = @(f,A,f0,gamma,bg) A*gamma./((f - f0).^2 + gamma^2)+bg;
doubleLorentzian = @(f,A1,A2,f1,f2,gamma1,gamma2,bg1,bg2) ...
    Lorentzian(f,A1,f1,gamma1,bg1)+Lorentzian(f,A2,f2,gamma2,bg2);

params_guess(1) = 8.386e-4; %A1
params_guess(2) = 2.365e-4; %A2
params_guess(3) = 7.37; %f1
params_guess(4) = 7.48; %f2
params_guess(5) = 1.977e-2; %gamma1
params_guess(6) = 3.7617e-3; %gamma2
params_guess(7) = 1.9947e-2; %bg1
params_guess(8) = 1.817e-2; %bg2

%%

freq_01_guess = @(Phi) 1500*(Phi-0.5).^2+7.254;
freq_02_guess = @(Phi) 1500*(Phi-0.5).^2+7.374;

%% 

numPhiPoints = numel(Phi_Q6_range);
numFrequencyPoints = numel(Freq_Q6_range);
frequency_01 = zeros(1,numPhiPoints);
frequency_02 = zeros(1,numPhiPoints);

for Phi_i = 1:numPhiPoints
    
    params_guess(3) = freq_01_guess(Phi_Q6_range(Phi_i)); %f1
    params_guess(4) = freq_02_guess(Phi_Q6_range(Phi_i)); %f2
    
%     lowerbound = 0.95*params_guess;
%     upperbound = 1.05*params_guess;
    
    data_Phi = Data_Q6_bg(:,Phi_i);
    residue = @(params) sum((data_Phi.' - ...
        doubleLorentzian(Freq_Q6_range,params(1),params(2),params(3),...
        params(4),params(5),params(6),params(7),params(8))).^2)/numFrequencyPoints;
    search_options = optimset('Display','notify','MaxIter',5e3,'MaxFunEvals',5e3,'TolFun',1e-5,'TolX',1e-5);
    params_min = fminsearch(residue,params_guess,search_options);
%     params_min = fminsearchbnd(residue,lowerbound,upperbound,params_guess,search_options);

    frequency_01(Phi_i) = params_min(3);
    frequency_02(Phi_i) = params_min(4);
end

%%

Freq_min = 7.2;
Freq_max = max(Freq_Q6_range);

figure3 = figure;
axes3 = axes('Parent',figure3);
imagesc(Phi_Q6_range,Freq_Q6_range,Data_Q6_bg)
set(gca,'Ydir','normal')
hold on
plot(Phi_Q6_range,frequency_01,'.','markersize',20,'DisplayName','\omega_{01}')
plot(Phi_Q6_range,frequency_02,'.','color',[0 0.5 0],'markersize',20,'DisplayName','\omega_{02}')
set(gca,'FontSize',24)
xlabel('\fontname{times}\fontsize{36}\Phi (\Phi_0)')
ylabel('\fontname{times}\fontsize{36}Frequency (GHz)')

h_legend = legend(axes3,'show');
set(h_legend,'FontSize',20,'location','bestoutside')
axis([Phi_Q6_range(1), Phi_Q6_range(end), Freq_min, Freq_max])
