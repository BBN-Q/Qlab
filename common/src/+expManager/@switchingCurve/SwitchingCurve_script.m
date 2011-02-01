% This script will execute the experiment SwitchingCurve using the
% default parameters found in the cfg file SwitchingCurve_v1_XXX.cfg,
% where XXX is given by the cfg_verion_number, after the experiment the
% the output data file will be printed to the command prompt.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%     CLEAR      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

temp = instrfind;
if ~isempty(temp)
    fclose(temp)
    delete(temp)
end
clear temp

clear all
close all
clear classes
fclose('all');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     BASIC INPUTS      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

base_path = 'C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\';
cfg_file_number = 8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     INITIALIZE PATH     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

restoredefaultpath
addpath([ base_path 'ExpTree\RunExp\src\matlab\' ]);
addpath([ base_path 'ExpTree\SwitchingCurve\src\matlab\' ]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%     PREPARE FOR EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These methods are inherited from the superclass 'experiment'.  They are
% generic for all Experiments
Exp = SwitchingCurve(base_path,cfg_file_number);
Exp.setPath;
Exp.parseCFG;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%     MODIFY PARAMETERS      %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parameters can be altered either by changing the cfg file or by adjusting
% parameters here.  Below is a list of the parameters that are most likely
% to be changed.  It is recommended that you treat the cfg file as a set of
% default parameters and only change the cfg file when a new instrument is
% added, or there is a major change to the experimental setup.

% NOTE: if significant changes are made to the cfg file, this section of
% the script will have to be changed to be consistent with those changes

Exp.inputStructure.InitParams.fluxPulse.DontReprogram = 0; % is this flag equals 1 the 
                                            % tek AWG waveforms will not be reloaded
                                       
if  Exp.inputStructure.InitParams.fluxPulse.DontReprogram
    fprintf('#########################################################\n')
    fprintf('####### Warning: Tek AWG is not being reprogrammed ######\n')
    fprintf('#########################################################\n')
end
% Number of trigger pulses output by trigger source (and therefore number
% of waveforms sent to qubit at each loop iteration);
Exp.inputStructure.InitParams.triggerSource.numWaveforms = 200;

                 %6.7 GHz      %9GHz
slope =         -0.5489;%-.6478%-.8779;%-1.0783;%-0.9106;%     -0.8424;%-0.8788;%    
intercept =     0.0810;%1.2069;%2.0452;%1.75;%1.8;%   1.6824;%1.7426-0.0131;%1.7715;

v3_function = @(x) slope*x+intercept;

% These are the initial values for the voltage levels of the flux pulse.
% If these parameters are not looped then these are the value they will
% stay at throughout the experiment
TimeAmpParams.v0_amp_start = -.5;%0 %in V
TimeAmpParams.v1_amp_start = 3;%1.3%4.15%4.1;%4.0; %in V
TimeAmpParams.v2_amp_start =  0.02;%.3213;%1.219;%1.213%1.233%1.525;%1.6;%1.512; %in V
% TimeAmpParams.v3_amp_start = 0.02;%0.1262;%0.2149;%0.085;%0.137;% %in V
TimeAmpParams.v3_amp_start = v3_function(TimeAmpParams.v2_amp_start);%0.3947;%(2.05-TimeAmpParams.v2_amp_start)/1.3; %in V
% TimeAmpParams.squid_bias_start= .005;
% If any of the parameters are looped, these will be their final values
TimeAmpParams.v0_amp_end   = .5; %in V
TimeAmpParams.v1_amp_end   = 3.6; %in V
TimeAmpParams.v2_amp_end   = .4; %1.550; %in V
% TimeAmpParams.v3_amp_end   = 0.12;%0.085;% %in V
TimeAmpParams.v3_amp_end   = v3_function(TimeAmpParams.v2_amp_end);%0.2053;%(2.05-TimeAmpParams.v2_amp_end)/1.3; %in V
% TimeAmpParams.squid_bias_end = -.05;

% Exp.inputStructure.ExpParams.readoutPulse.amp.start(1:9)=[0;0;TimeAmpParams.squid_bias_start;TimeAmpParams.squid_bias_start;1;1;1;1;0]; %dimensionless
% Exp.inputStructure.ExpParams.readoutPulse.amp.end(1:9)=[0;0;TimeAmpParams.squid_bias_end;TimeAmpParams.squid_bias_end;1;1;0.6;0.6;0]; %dimensionless

% pulse timing values in ns.  See white board
TimeAmpParams.t0_start = 0;      %in ns
TimeAmpParams.t1_start = 30000;    %in ns
TimeAmpParams.t2_start = 51990;    %in ns
TimeAmpParams.t3_start = 52000;    %in ns
TimeAmpParams.t4_start = 190000;   %in nsf
TimeAmpParams.tR_start = 200000; %in ns

TimeAmpParams.t0_end = 0;      %in ns
TimeAmpParams.t1_end = 5000;    %in ns
TimeAmpParams.t2_end = 5900;    %in ns
TimeAmpParams.t3_end = 6000;    %in ns
TimeAmpParams.t4_end = 40000;   %in ns
TimeAmpParams.tR_end = 45000; %in ns

% TimeAmpParams.t0_end   = 0;      %in ns
% TimeAmpParams.t1_end   = 110;    %in ns
% TimeAmpParams.t2_end   = 350;    %in ns
% TimeAmpParams.t3_end   = 420;    %in ns
% TimeAmpParams.t4_end   = 1010;   %in ns
% TimeAmpParams.tR_end   = 1.2e-3; %in ns

TimeAmpParams.v1_time_rise  = 1000; %in ns
TimeAmpParams.v2_time_rise  = 100; %in ns
%this gives the shortest possible measurement pulse
TimeAmpParams.v3_time_rise  = 1/1.2;  %in ns
TimeAmpParams.v3_duration   = 2;

[Exp.inputStructure.ExpParams] = initExpParams(Exp.inputStructure.ExpParams,TimeAmpParams);

%Exp.inputStructure.ExpParams.v2_pulse.offset.start = -2;

% timing of the microwave pulse.  In cfg 002, the v2_pulse begins at 
% t = 120 ns and the measurement pulse (v3) begins at t = 350 ns, the delay
% due to the mixer boxes is about 20 ns.
muwave_pulse_t_begin_start  = 51070;
muwave_pulse_t_end_start    = 51970;
muwave_pulse_riseTime_start = 10;

muwave_pulse_t_begin_end  = 51630;
muwave_pulse_t_end_end    = 51670;
muwave_pulse_riseTime_end = 10;

Exp.inputStructure.ExpParams.MicrowavePulse.time.start(1:4) = [muwave_pulse_t_begin_start muwave_pulse_riseTime_start (muwave_pulse_t_end_start-muwave_pulse_t_begin_start) muwave_pulse_riseTime_start]*1e-9;
Exp.inputStructure.ExpParams.MicrowavePulse.time.end(1:4) = [muwave_pulse_t_begin_end muwave_pulse_riseTime_end (muwave_pulse_t_end_end-muwave_pulse_t_begin_end) muwave_pulse_riseTime_end]*1e-9;
 
Exp.inputStructure.ExpParams.v1_pulse.amp.start   = [0;0;0;0;0];
Exp.inputStructure.ExpParams.v2_pulse.amp.start   = [0;0;0;0;0];
Exp.inputStructure.ExpParams.v3_pulse.amp.start   = [0;0;0;0;0];
Exp.inputStructure.ExpParams.MicrowavePulse.amp.start   = [0;0;0;0;0];

%%!!!!!!!!!!!!!Warning:  Miteq 8-12 GHZ amp at output of mixers, 
% maximum power should be -5 dBm at source this equals -25 dBm at amp in and 5 dBm output DO NOT EXCEED!!!!!!!
% we used 10 dBm at sourcec as max for last run so this was in reality
% -10dBm after the mixers  so to replicate source now should be -20dBm

% muwave 1 is the nomianlly the 12 drive
Exp.inputStructure.ExpParams.muwave1.frequency.start  =     4;%5.65;%5.83; % min frequency in GHz0
Exp.inputStructure.ExpParams.muwave1.frequency.end    =     8; % max frequency in GHz
Exp.inputStructure.ExpParams.muwave1.power.start      =     -19; % min power in dBm
Exp.inputStructure.ExpParams.muwave1.power.end        =     -30; % max power in dBm

% % muwave 2 is nomianlly the 02 drive
% Exp.inputStructure.ExpParams.muwave2.frequency.start =     6.4;%6.0429; % min frequency in GHz
% Exp.inputStructure.ExpParams.muwave2.frequency.end   =     6.6; % max frequency in GHz
% Exp.inputStructure.ExpParams.muwave2.power.start     =     -17;%-6.5; % min frequency in dBm
% Exp.inputStructure.ExpParams.muwave2.power.end       =     5;%-3.5; % max frequency in dBm

% % Not being used for now
% % muwave 3 can't go above -12 dBm or below -20 dBm
% Exp.inputStructure.ExpParams.muwave3.frequency.start =     5; % min frequency in GHz
% Exp.inputStructure.ExpParams.muwave3.frequency.end   =     6; % max frequency in GHz
% Exp.inputStructure.ExpParams.muwave3.power.start     =     -19; % min frequency in dBm
% Exp.inputStructure.ExpParams.muwave3.power.end       =     -10; % max frequency in dBm
% 


Exp.inputStructure.ExpParams.readoutPulse.maxAmp.start = 0.01;%1.475;%4.15;%%4.233; %in V
Exp.inputStructure.ExpParams.readoutPulse.maxAmp.end   = 0.10; %in V

% for now just remove tasks that are not necessary
Exp.inputStructure.ExpParams = rmfield(Exp.inputStructure.ExpParams,'v1_pulse');
Exp.inputStructure.ExpParams = rmfield(Exp.inputStructure.ExpParams,'v2_pulse');
Exp.inputStructure.ExpParams = rmfield(Exp.inputStructure.ExpParams,'v3_pulse');
Exp.inputStructure.ExpParams = rmfield(Exp.inputStructure.ExpParams,'MicrowavePulse');
Exp.inputStructure.ExpParams = rmfield(Exp.inputStructure.ExpParams,'muwave1');
% Exp.inputStructure.ExpParams = rmfield(Exp.inputStructure.ExpParams,'muwave2');

setLoops = true;
% if setLoops = false, the experiment will run with whatever loop
% parameters are in the cfg file
if setLoops
    LoopParams.readoutPulse.name                             =         'readoutPulse_Loop'; %Loop name
    LoopParams.readoutPulse.number                           =         1; % 1-3, 1 being the innermost
    LoopParams.readoutPulse.steps                            =         30; % number of iterations
    LoopParams.readoutPulse.taskName                         =         {'readoutPulse'}; % which task does it pertain to?
    LoopParams.readoutPulse.parameter                        =         {'maxAmp'}; % which parameter will be changed
    readoutPulse_conversionFactor = 1/10/100e3*1e6; %conversion from volts to muA
    LoopParams.readoutPulse.plotRange.start                  =         readoutPulse_conversionFactor*Exp.inputStructure.ExpParams.readoutPulse.maxAmp.start;
    LoopParams.readoutPulse.plotRange.end                    =         readoutPulse_conversionFactor*Exp.inputStructure.ExpParams.readoutPulse.maxAmp.end;

%     LoopParams.bothpowers.name                             =         'power'; %Loop name
%     LoopParams.bothpowers.number                           =         3; % 1-3, 1 being the innermost
%     LoopParams.bothpowers.steps                            =         3; % number of iterations
%     LoopParams.bothpowers.taskName                         =         {'muwave1';'muwave2'}; % which task does it pertain to?
%     LoopParams.bothpowers.parameter                        =         {'power';'power'}; % which parameter will be changed
%     bothpowers_conversionFactor =1; %conversion from V to mA
%     LoopParams.bothpowers.plotRange.start                  =         bothpowers_conversionFactor*Exp.inputStructure.ExpParams.muwave1.power.start;
%     LoopParams.bothpowers.plotRange.end                    =         bothpowers_conversionFactor*Exp.inputStructure.ExpParams.muwave1.power.end;
% % 
%     LoopParams.power1.name                             =         'power'; %Loop name
%     LoopParams.power1.number                           =         2; % 1-3, 1 being the innermost
%     LoopParams.power1.steps                            =         10; % number of iterations
%     LoopParams.power1.taskName                         =         {'muwave1'}; % which task does it pertain to?
%     LoopParams.power1.parameter                        =         {'power'}; % which parameter will be changed
%     power1_conversionFactor =1; %conversion from V to mA
%     LoopParams.power1.plotRange.start                  =         power1_conversionFactor*Exp.inputStructure.ExpParams.muwave1.power.start;
%     LoopParams.power1.plotRange.end                    =         power1_conversionFactor*Exp.inputStructure.ExpParams.muwave1.power.end;
%     
%     LoopParams.power2.name                             =         'power'; %Loop name
%     LoopParams.power2.number                           =         1; % 1-3, 1 being the innermost
%     LoopParams.power2.steps                            =         5; % number of iterations
%     LoopParams.power2.taskName                         =         {'muwave2'}; % which task does it pertain to?
%     LoopParams.power2.parameter                        =         {'power'}; % which parameter will be changed
%     power2_conversionFactor =1; %conversion from V to mA
%     LoopParams.power2.plotRange.start                  =         power2_conversionFactor*Exp.inputStructure.ExpParams.muwave2.power.start;
%     LoopParams.power2.plotRange.end                    =         power2_conversionFactor*Exp.inputStructure.ExpParams.muwave2.power.end;
% 
%     LoopParams.frequency2.name                             =         'frequency'; %Loop name
%     LoopParams.frequency2.number                           =         2; % 1-3, 1 being the innermost
%     LoopParams.frequency2.steps                            =         15; % number of iterations
%     LoopParams.frequency2.taskName                         =         {'muwave2'}; % which task does it pertain to?
%     LoopParams.frequency2.parameter                        =         {'frequency'}; % which parameter will be changed
%     frequency2_conversionFactor =1; %conversion from V to mA
%     LoopParams.frequency2.plotRange.start                  =         frequency2_conversionFactor*Exp.inputStructure.ExpParams.muwave2.frequency.start;
%     LoopParams.frequency2.plotRange.end                    =         frequency2_conversionFactor*Exp.inputStructure.ExpParams.muwave2.frequency.end;
% %     
%     LoopParams.frequency1.name                             =         'frequency'; %Loop name
%     LoopParams.frequency1.number                           =         2; % 1-3, 1 being the innermost
%     LoopParams.frequency1.steps                            =         40; % number of iterations
%     LoopParams.frequency1.taskName                         =         {'muwave1'}; % which task does it pertain to?
%     LoopParams.frequency1.parameter                        =         {'frequency'}; % which parameter will be changed
%     frequency1_conversionFactor =1; %conversion from V to mA
%     LoopParams.frequency1.plotRange.start                  =         frequency1_conversionFactor*Exp.inputStructure.ExpParams.muwave1.frequency.start;
%     LoopParams.frequency1.plotRange.end                    =         frequency1_conversionFactor*Exp.inputStructure.ExpParams.muwave1.frequency.end;

%     LoopParams.v2_amp.name                             =         'flux_loop'; %Loop name
%     LoopParams.v2_amp.number                           =         2; % 1-3, 1 being the innermost
%     LoopParams.v2_amp.steps                            =         20; % number of iterations
%     LoopParams.v2_amp.taskName                         =         {'v2_pulse'};%,'v3_pulse'}; % which task does it pertain to?
%     LoopParams.v2_amp.parameter                        =         {'maxAmp'};%,'maxAmp'}; % which parameter will be changed
%     v2_amp_conversionFactor = 1;%10^(-29/20)/50*1e3; %conversion from V to mA
%     LoopParams.v2_amp.plotRange.start                  =         v2_amp_conversionFactor*Exp.inputStructure.ExpParams.v2_pulse.maxAmp.start;
%     LoopParams.v2_amp.plotRange.end                    =         v2_amp_conversionFactor*Exp.inputStructure.ExpParams.v2_pulse.maxAmp.end;

%     LoopParams.v3_amp.name                             =         'flux_loop'; %Loop name
%     LoopParams.v3_amp.number                           =         2; % 1-3, 1 being the innermost
%     LoopParams.v3_amp.steps                            =         20; % number of iterations
%     LoopParams.v3_amp.taskName                         =         {'v3_pulse'}; % which task does it pertain to?
%     LoopParams.v3_amp.parameter                        =         {'maxAmp'}; % which parameter will be changed
%     v3_amp_conversionFactor = 1;%10^(-29/20)/50*1e3; %conversion from V to mA
%     LoopParams.v3_amp.plotRange.start                  =         v3_amp_conversionFactor*Exp.inputStructure.ExpParams.v3_pulse.maxAmp.start;
%     LoopParams.v3_amp.plotRange.end                    =         v3_amp_conversionFactor*Exp.inputStructure.ExpParams.v3_pulse.maxAmp.end;
% 
%     LoopParams.v1_amp.name                             =         'flux2_loop'; %Loop name
%     LoopParams.v1_amp.number                           =         1; % 1-3, 1 being the innermost
%     LoopParams.v1_amp.steps                            =         20; % number of iterations
%     LoopParams.v1_amp.taskName                         =         {'v1_pulse'}; % which task does it pertain to?
%     LoopParams.v1_amp.parameter                        =         {'maxAmp'}; % which parameter will be changed
%     v1_amp_conversionFactor = 1; %conversion from V to mA
%     LoopParams.v1_amp.plotRange.start                  =         v1_amp_conversionFactor*Exp.inputStructure.ExpParams.v1_pulse.maxAmp.start;
%     LoopParams.v1_amp.plotRange.end                    =         v1_amp_conversionFactor*Exp.inputStructure.ExpParams.v1_pulse.maxAmp.end;
%     
%    LoopParams.v0_offset.name                             =         'v0'; %Loop name
%     LoopParams.v0_offset.number                           =         2; % 1-3, 1 being the innermost
%     LoopParams.v0_offset.steps                            =         100; % number of iterations
%     LoopParams.v0_offset.taskName                         =         {'v1_pulse'}; % which task does it pertain to?
%     LoopParams.v0_offset.parameter                        =         {'offset'}; % which parameter will be changed
%     v0_offset_conversionFactor = 1; %conversion from V to mA
%     LoopParams.v0_offset.plotRange.start                  =         v0_offset_conversionFactor*Exp.inputStructure.ExpParams.v1_pulse.offset.start;
%     LoopParams.v0_offset.plotRange.end                    =         v0_offset_conversionFactor*Exp.inputStructure.ExpParams.v1_pulse.offset.end;
%         
%     LoopParams.MicrowaveModulation.name                =         'MicrowaveModulation'; %Loop name
%     LoopParams.MicrowaveModulation.number              =         1; % 1-3, 1 being the innermost
%     LoopParams.MicrowaveModulation.steps               =         40; % number of iterations
%     LoopParams.MicrowaveModulation.taskName            =         {'MicrowavePulse';'MicrowavePulse'}; % which task does it pertain to?
%     LoopParams.MicrowaveModulation.parameter           =         {'time';'amp'}; % if you change time, you also have to "change" amp
% %     LoopParams.MicrowaveModulation.plotRange.start     =         muwave_pulse_t_end_start-muwave_pulse_t_begin_start;
% %     LoopParams.MicrowaveModulation.plotRange.end       =         muwave_pulse_t_end_end-muwave_pulse_t_begin_end;
%     LoopParams.MicrowaveModulation.plotRange.start     =         TimeAmpParams.t2_start-muwave_pulse_t_end_start;
%     LoopParams.MicrowaveModulation.plotRange.end       =         TimeAmpParams.t2_start-muwave_pulse_t_end_end;
%      
%     LoopParams.readoutPulse.name                =         'readoutPulseSQB'; %Loop name
%     LoopParams.readoutPulse.number              =         2; % 1-3, 1 being the innermost
%     LoopParams.readoutPulse.steps               =         2; % number of iterations
%     LoopParams.readoutPulse.taskName            =         {'readoutPulse';'readoutPulse'}; % which task does it pertain to?
%     LoopParams.readoutPulse.parameter           =         {'amp';'time'}; % if you change time, you also have to "change" amp
%     %LoopParams.readoutPulse.plotRange.start     =         Exp.inputStructure.ExpParams.readoutPulse.offset.start;
%     %LoopParams.readoutPulse.plotRange.end       =         Exp.inputStructure.ExpParams.readoutPulse.offset.end;
%     LoopParams.readoutPulse.plotRange.start     =         TimeAmpParams.squid_bias_start;
%     LoopParams.readoutPulse.plotRange.end       =         TimeAmpParams.squid_bias_end;
%   
%     LoopParams.pi_pulse.name                             =         'pi_pulse'; %Loop name
%     LoopParams.pi_pulse.number                           =         2; % 1-3, 1 being the innermost
%     LoopParams.pi_pulse.steps                            =         2; % number of iterations
%     LoopParams.pi_pulse.taskName                         =         {'v2_pulse';'MicrowavePulse';'MicrowavePulse'}; % which task does it pertain to?
%     LoopParams.pi_pulse.parameter                        =         {'maxAmp';'time';'amp'}; % which parameter will be changed
%     pi_pulse_conversionFactor = 1;%10^(-29/20)/50*1e3; %conversion from V to mA
%     LoopParams.pi_pulse.plotRange.start                  =         pi_pulse_conversionFactor*Exp.inputStructure.ExpParams.v2_pulse.maxAmp.start;
%     LoopParams.pi_pulse.plotRange.end                    =         pi_pulse_conversionFactor*Exp.inputStructure.ExpParams.v2_pulse.maxAmp.end;
% 
%     LoopParams.v2_amp.name                             =         'flux_loop'; %Loop name
%     LoopParams.v2_amp.number                           =         1; % 1-3, 1 being the innermost
%     LoopParams.v2_amp.steps                            =        40; % number of iterations
%     LoopParams.v2_amp.taskName                         =         {'v2_pulse';'v3_pulse'};%,'v3_pulse'}; % which task does it pertain to?
%     LoopParams.v2_amp.parameter                        =         {'maxAmp';'maxAmp'};%,'maxAmp'}; % which parameter will be changed
%     v2_amp_conversionFactor = 1;%10^(-29/20)/50*1e3; %conversion from V to mA
%     LoopParams.v2_amp.plotRange.start                  =         v2_amp_conversionFactor*Exp.inputStructure.ExpParams.v2_pulse.maxAmp.start;
%     LoopParams.v2_amp.plotRange.end                    =         v2_amp_conversionFactor*Exp.inputStructure.ExpParams.v2_pulse.maxAmp.end;
     

    % delete any loops that may already exist and replace witht the loops above
    Exp.inputStructure = rmfield(Exp.inputStructure,'LoopParams');
    Exp.inputStructure.LoopParams = LoopParams;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%     RUN THE EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the data file and record the (possibly altered) parameters
Exp.openDataFile;
Exp.writeDataFileHeader;

% Run the actual experiment
Exp.Init;
Exp.Do;
Exp.CleanUp;

% Close the data file and end connection to all insturments.  This is 
% another method inherited from 'experiment'
Exp.finalizeData;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%     PRINT DATA AND CHECK HEADER      %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Now we print the output file (header and data) to the command prompt
fprintf('\nStart of Data Output File print out\n');
type(Exp.DataFileName);
fprintf('\nEnd of Data Output File print out\n\n');

% Now we can parse the header to recover the inputStructure
header = true;
headerStructure = parse_ExpcfgFile(Exp.DataFileName,header);

% This function will compare the two structures and make sure that they
% match.
[HeaderFields InputFields err] = comp_struct(headerStructure,Exp.inputStructure,...
    'headerStructure','inputStructure');

if isempty(err)
    fprintf('\nSucess: inputStructure matches header data\n');
else
    fprintf('\ninputStructure does not match header data\n');
    display(HeaderFields);display(InputFields);display(err);
end