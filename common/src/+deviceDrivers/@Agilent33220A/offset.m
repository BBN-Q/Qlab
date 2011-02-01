function offset(obj,value,Params) %#ok<INUSD>

fprintf(obj.GPIBHandle,sprintf('VOLT:OFFSET %d',value));

end