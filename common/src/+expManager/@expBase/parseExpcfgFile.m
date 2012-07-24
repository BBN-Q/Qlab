function CFG = parseExpcfgFile(obj)
% CFG = parseExpcfgFile(obj)
% Load experimental configuration from file at obj.cfgFileName.

obj.inputStructure = jsonlab.loadjson(obj.cfgFileName);

% make sure we at least have 'InstrParams' and 'SweepParams' keys.
if ~isfield(obj.inputStructure, 'InstrParams')
	obj.inputStructure.InstrParams = struct();
end

if ~isfield(obj.inputStructure, 'SweepParams')
	obj.inputStructure.SweepParams = struct();
end

end

