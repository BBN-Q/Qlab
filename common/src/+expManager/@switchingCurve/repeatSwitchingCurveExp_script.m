
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     BASIC INPUTS      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

base_path = 'C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\';
cfg_file_number = 6;

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
%%%%%%%%%%%%%%%%%%%%%%     LOAD INPUT PARAMETERS      %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DataFileName = 'SwitchingCurve_v1_20100208T121536.out';

Exp.inputStructure = parse_ExpcfgFile(DataFileName,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   MODIFY INPUT PARAMETERS      %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Exp.inputStructure.LoopParams.readoutPulse.steps = 20;
Exp.inputStructure.LoopParams.v0_offset.steps    = 20;

% Exp.inputStructure.ExpParams.muwave1.power.start = -17;
% Exp.inputStructure.ExpParams.muwave1.power.end   = -11;
% 
% Exp.inputStructure.InitParams.triggerSource.numWaveforms = 1000;
% 
% Exp.inputStructure.ExpParams.muwave1.frequency.start = 5.75;
% Exp.inputStructure.ExpParams.muwave1.frequency.end   = 6.0;
% 
% Exp.inputStructure.ExpParams.muwave2.frequency.start = 5.95;
% Exp.inputStructure.ExpParams.muwave2.frequency.end   = 6.1;
% 
% Exp.inputStructure.LoopParams.frequency1.plotRange.start = Exp.inputStructure.ExpParams.muwave1.frequency.start;
% Exp.inputStructure.LoopParams.frequency1.plotRange.end   = Exp.inputStructure.ExpParams.muwave1.frequency.end;
% 
% Exp.inputStructure.LoopParams.frequency2.plotRange.start = Exp.inputStructure.ExpParams.muwave2.frequency.start;
% Exp.inputStructure.LoopParams.frequency2.plotRange.end   = Exp.inputStructure.ExpParams.muwave2.frequency.end;

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