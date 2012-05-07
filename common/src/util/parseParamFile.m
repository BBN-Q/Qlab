function CFG = parseParamFile(filename,header)

comment = '#';
startHeader = '$$$ Beginning of Header';
endHeader   = '$$$ End of Header';

% Open file
fid = fopen(filename,'r');
if (fid < 0), error('Unable to open file %s',filename); end

CFG = []; 

% Put config file name in configuration structure so CFG parameters
% can be reconstructed for a given configuration file 
CFG.cfg_file_name = filename;

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
        pstr = sprintf('In %s, Key <%s> has no value',filename,linedat{1});
        perr = 1;
        break
    end
    
    if(strcmp(linedat(1), comment)), continue; end
    value_str = char(linedat{2});
    if (isstrprop(value_str(1), 'digit') || (strcmp(value_str(1), '-')) || (strcmp(value_str(1), '+')) ...
       || (strcmp(value_str(1), '.') &&  isstrprop(value_str(2), 'digit'))) && length(strfind(value_str,'.')) <= 1 %avoid IP address
        % Number assignments
        eval(['CFG.',linedat{1},' = str2num(linedat{2});']);
    elseif(strcmp(value_str(1), '['))
        % Array assignments
         eval(['CFG.', linedat{1},' = ',linedat{2},';']);
    elseif(strcmp(value_str(1), '{'))
        % cell assignments
         eval(['CFG.', linedat{1},' = ',linedat{2},';']);
    else
        eval(['CFG.', linedat{1},' = strtrim(sprintf(''%s '', linedat{2:end}));']);
    end
end

fclose(fid);

end