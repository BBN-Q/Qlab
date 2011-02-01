function offset(obj,value,Params)

channel_str = sprintf('chan_%d',Params.taskParameters.pulseCH);
if abs(value) > 2
    error('offset cannot be greater than +/- 2 V')
end
obj.(channel_str).offset = value;

end