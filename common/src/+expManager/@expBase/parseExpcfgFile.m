function [CFG] = parseExpcfgFile(obj, header)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE:  CFG = parse_PulseParam_cfg( cfg_file_name )
% Description: function to parse the CBL primitive calibration pulse parameters config file
% Returns the contents of this file in the 'CFG' structure
% Input:   cfg_file_name - Configuration file name 
%          cfg_file_type - Conifiguration file type : QUBITPARAM = 1, PULSE = 2, INTEG = 3; 
%          header        - an optional input that can be used to tell the
%          routine that the file being read is the header of a data file.
%          The only effect this will have is if header is non-zero then any
%          text appearing before the startHeader string will be ignored.
%          header defaults to 'false'.
% Output:  Matlab structure CFG which contains fields given in configuration 
%            file and their associated values.
% v1.1 9 JULY 2008 Erin M Aylward <eaylward@bbn.com> Intial version. Note a configuration
%            file parser is better than just running an m file set up to store config
%            parameters in a matlab structure becuase parseing the config file in a function
%            allows for error checking on the configuration parameters.
% v1.2 18 DEC 2008 - compbined various parsers into a single parser. 
% v1.3 9 JULY 2009 William Kelly <wkelly@bbn.com> adapted for use with
%            cryo-lab software architecture.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

obj.inputStructure = parseParamFile(obj.cfgFileName);
if ~isfield(obj.inputStructure, 'InstrParams')
	obj.inputStructure.InstrParams = struct();
end
if ~isfield(obj.inputStructure, 'TaskParams')
	obj.inputStructure.TaskParams = struct();
end
if ~isfield(obj.inputStructure, 'SweepParams')
	obj.inputStructure.SweepParams = struct();
end

end

% Calculate some sizes etc. based on conifiguration file type and 
% parameters in configuration file


