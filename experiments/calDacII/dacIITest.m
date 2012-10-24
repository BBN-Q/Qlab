% This script will calibrate DCBias board

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
fclose all
clear classes
clear import

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     BASIC INPUTS      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get base path by looking up M filename and searching for the top
% of the tree
script_path = mfilename('fullpath');
extended_path = '\experiments\';
baseIdx = strfind(script_path,extended_path);
base_path = script_path(1:baseIdx);

cfg_file_number = 1;
cfg_file_name = ['calDacII_v1_001.cfg'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     INITIALIZE PATH     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

restoredefaultpath
addpath([ base_path 'common/src/'],'-END');
addpath([ base_path 'common/src/util'],'-END');
addpath([ base_path 'experiments/calDacII/cfg/'],'-END');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%     PREPARE FOR EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These methods are inherited from the superclass 'experiment'.  They are
% generic for all Experiments
Exp = expManager.calDacII(base_path,cfg_file_name);
Exp.setPath;
Exp.parseExpcfgFile;

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

