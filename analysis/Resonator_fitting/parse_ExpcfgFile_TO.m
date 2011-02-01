function CFG = parse_ExpcfgFile_TO(cfg_file_name)
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

% These two variables are hard coded because they should really never be
% changed.
comment = '#';
startHeader = '$$$ Start of header';
endHeader   = '$$$ End of header';

% Open file
fid = fopen(cfg_file_name,'r');
if (fid < 0), error('Unable to open file %s',cfg_file_name); end

perr = 0;
pstr = '';
CFG = []; 

% Put config file name in configuration structure so CFG parameters
% can be reconstructed for a given configuration file 
CFG.cfg_file_name = cfg_file_name;

if ~exist('header','var')
    % The default assumption is we are reading a cfg file
    header = false;
    startReading = true;
else
    if header
        % if we're reading a header, we shouldn't start until we see the
        % begin header string
        startReading = false;
    end
end
while true
    tline = fgetl(fid); % returns the next line of a file associated with file
                        % identifier FID as a MATLAB string
    if (tline == -1), break; end
    % If we see the startHeader string, then we start looking for the end
    % of header string.  Note that any data before the startHeader string
    % WILL be parsed.
    if ~isempty(findstr(tline,startHeader))
        header = true;
        startReading = true;
        continue;
    end
    % If we see the endHeader string then we quit.
    if ~isempty(findstr(tline,endHeader)) && header
        break
    end
    if (isempty(tline) || strcmp(tline(1),comment) || isspace(tline(1)) || ~startReading)
        continue;
    end
    linedat = strread(tline,'%s');
    % If we have reached the end of the header than we can quit
    if (length(linedat) <= 1)
        pstr = sprintf('In %s, Key <%s> has no value',cfg_file_name,linedat{1});
        perr = 1;
        break
    end
    
    if(strcmp(linedat(1), comment)), continue; end
    value_str = char(linedat{2});
    if isstrprop(value_str(1), 'digit') || (strcmp(value_str(1), '-')) || (strcmp(value_str(1), '+')) ...
       || (strcmp(value_str(1), '.') &&  isstrprop(value_str(2), 'digit'))
        % Number assignments
        eval(['CFG.',linedat{1},' = str2num(linedat{2});']);
    elseif(strcmp(value_str(1), '['))
        % Array assignments
         eval(['CFG.', linedat{1},' = ',linedat{2},';']);
    elseif(strcmp(value_str(1), '{'))
        % cell assignments
         eval(['CFG.', linedat{1},' = ',linedat{2},';']);
    else
        eval(['CFG.', linedat{1},' = linedat{2};']);
    end
end

% Close file. Parse errors?
fclose(fid); if (perr), error(pstr); end


% Calculate some sizes etc. based on conifiguration file type and 
% parameters in configuration file


