% This script will execute the experiment homodyneDetection using the
% default parameters found in the cfg file homodyneDetection_v1_XXX.cfg,
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
clear all;
close all;
fclose all;
clear classes
clear import

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     BASIC INPUTS      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%base_path = 'C:\Documents and Settings\Administrator\My Documents\qlabDevelopement\qlab\';
%base_path = '/Users/rrosales/PROJECTS/BUQ/qlabTest/';
%base_path = 'C:\Documents and Settings\QLab\Desktop\SVN\qlab\';
% base_path is up two levels from this file
[base_path] = fileparts(mfilename('fullpath'));
% go up two levels
pos = find(base_path == filesep, 1, 'last');
base_path = base_path(1:pos-1);
pos = find(base_path == filesep, 1, 'last');
base_path = base_path(1:pos);

data_path = [base_path 'experiments/muWaveDetection/data/'];

cfg_file_number = 6;
cfg_file_name = 'homodyneDetection_v1_006.cfg';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     INITIALIZE PATH     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

restoredefaultpath
addpath([ base_path 'experiments/muWaveDetection/'],'-END');
addpath([ base_path 'common/src'],'-END');
addpath([ base_path,'experiments/muWaveDetection/cfg'],'-END');
addpath([ base_path 'common/src/util/'],'-END');      

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%     PREPARE FOR EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These methods are inherited from the superclass 'experiment'.  They are
% generic for all Experiments
Exp = expManager.homodyneDetection(data_path,cfg_file_name, 'homodyne');
Exp.setPath;
Exp.parseExpcfgFile;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%     MODIFY PARAMETERS      %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




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
% fprintf('\nStart of Data Output File print out\n');
% type(Exp.DataFileName);
% fprintf('\nEnd of Data Output File print out\n\n');

% Now we can parse the header to recover the inputStructure
Exp.parseDataFile;
headerStructure = Exp.DataStruct.params;

% This function will compare the two structures and make sure that they
% match.
[HeaderFields InputFields err] = comp_struct(headerStructure,Exp.inputStructure,...
    'headerStructure','Exp.inputStructure');

if isempty(err)
    fprintf('\nSucess: inputStructure matches header data\n');
else
    fprintf('\ninputStructure does not match header data\n');
    display(HeaderFields);display(InputFields);display(err);
end
