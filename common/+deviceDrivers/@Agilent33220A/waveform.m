function errorMsg = waveform(obj,wfParams,Params)

[pulseData] = initializeWaveform(wfParams,obj.samplingRate,obj.waveformDuration);

% params_i = ExpParams.(Loop.taskName{i_task});
taskName_i = Params.taskParameters.taskName;
% deviceTag_i = Params.deviceTag;
wf_name =  taskName_i;

frequency = 1/obj.waveformDuration;
pulseData = pulseData/max(pulseData);

%%

if numel(wf_name) > 12
    wf_name = wf_name(1:12); %waveform names must have less than 12 characters
end

wf_string = 'DATA VOLATILE';
for n = 1:numel(pulseData)
    wf_string = [wf_string sprintf(', %d',pulseData(n))]; %#ok<AGROW>
end

num_bufferBytes = nextpow2(numel(wf_string));
if obj.GPIBHandle.OutputBufferSize < 2^num_bufferBytes
    fclose(obj.GPIBHandle);
    obj.GPIBHandle.OutputBufferSize = 2^num_bufferBytes;
    fopen(obj.GPIBHandle);
end

% First we turn off the output and set the AWG to DC mode, this prevents system conflicts when we try
% to overwrite memory.
fprintf(obj.GPIBHandle,'OUTPUT OFF');
% Find out how many free memroy slots there are
fprintf(obj.GPIBHandle,'DATA:NVOLatile:FREE?');
temp  = fscanf(obj.GPIBHandle);
numFreeMem = str2double(temp);
if numFreeMem == 0
    % All this mess below is because we have to delete a waveform (since memory
    % is full) but we can't delete the active waveform.
    fprintf(obj.GPIBHandle,'DATA:NVOLATILE:CATALOG?');
    catalog = fscanf(obj.GPIBHandle);
    fprintf(obj.GPIBHandle,'FUNC:USER?');
    currentwf = fscanf(obj.GPIBHandle);
    currentwf = currentwf(1:end-1); % delete the space at the end
    findquotes = findstr(catalog,'"');
    if mod(numel(findquotes),2)~=0,error('syntax error???'),end
    for wf_index = 1:(numel(findquotes)/2)
        wf_names{wf_index} = catalog( (findquotes(2*wf_index-1)+1) : (findquotes(2*wf_index)-1) );
    end
    wf_index = find(strcmp(currentwf,wf_names));
    if wf_index == 1
        wf2delete = wf_names{2};
    else
        wf2delete = wf_names{1};
    end
    fprintf(obj.GPIBHandle,sprintf('DATA:DELETE %s',wf2delete));
end
% Then we upload the data to volatile memory
fprintf(obj.GPIBHandle,wf_string)
fprintf(obj.GPIBHandle,sprintf('FREQ %d',frequency));
% Then we copy the waveform to non-volatile memery, giving it the
% appropritate name
fprintf(obj.GPIBHandle,sprintf('DATA:COPY %s',wf_name))
% This command selects the waveform
fprintf(obj.GPIBHandle,sprintf('FUNC:USER %s',wf_name))
fprintf(obj.GPIBHandle,'FUNC USER');
% The waveform will not actually be output until the command 
% "OUTPUT ON" is recieved

% for some reason this takes an unacceptably long time
% % return any errors
% errorIndex = 0;
% while 1
%     errorIndex = errorIndex+1;
%     fprintf(obj.GPIBHandle,'SYSTEM:ERROR?');pause(0.1)
%     errorMsg{errorIndex} = fscanf(obj.GPIBHandle);
%     if findstr('+0,"No error"',errorMsg{errorIndex})
%         break
%     end
%     if errorIndex > 10
%         break
%     end
% end
fprintf(obj.GPIBHandle,'OUTPut ON'); % Enable Output

timeout = 10; %seconds
t = clock;
while 1
    pause(0.1)
    fprintf(obj.GPIBHandle,'OUTPut?')
    temp = fscanf(obj.GPIBHandle);
    OutputValue = str2double(temp);
    if OutputValue == 1
        break
    end
    if etime(clock,t) > timeout
        errorMsg = 'Error: timeout';
        break
    end
end

end