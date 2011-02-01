function maxAmp(obj,value,Params)

channel_str = sprintf('chan_%d',Params.taskParameters.pulseCH);
obj.(channel_str).Amplitude = value;

end