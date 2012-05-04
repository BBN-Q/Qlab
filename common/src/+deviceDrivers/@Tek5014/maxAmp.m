function maxAmp(obj,value,Params)

channel_str = sprintf('chan_%d',Params.taskParameters.pulseCH);
obj.(channel_str).amplitude = value;

end