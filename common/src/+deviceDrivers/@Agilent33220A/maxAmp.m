function maxAmp(obj,maxAmp,Params)

% This is almost unforgivable, need to think about what to do here

% Here's the problem: the amplitude for the Agilent33220A is peak to peak
% amplitude, this means that the waveform shape and the maxAmp are not
% independent parameters, changing the waveform, but leaving peak to peak
% amplitude effectively changes maxAmp.

% I think the following code fixes the problem described above, but it
% hasn't been rigirously tested.
warning('possible inconsistency here')

maxWF = str2double(obj.Query('VOLTage:HIGH?'));
minWF = str2double(obj.Query('VOLTage:LOW?'));

if maxWF ~= 0
    amp_PtoP = 2*maxAmp*(maxWF-minWF)/maxWF; % This factor of 2 is bothersome, not sure why it's necessary but it is
elseif minWF ~= 0
    amp_PtoP = 2*maxAmp*(maxWF-minWF)/minWF;
else
    amp_PtoP = 2*maxAmp; % in this case we're just in DC mode so it doesn't really matter what the amplitude is
end
fprintf(obj.GPIBHandle,sprintf('VOLT %d',amp_PtoP));

end