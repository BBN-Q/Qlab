function random_update_Z(seq_file, varargin)
	[thisPath, ~] = fileparts(mfilename('fullpath'));
	if isempty(varargin)
		instrs_file = fullfile(thisPath, 'GST_1q_Z.pickle');
		Z_file = fullfile(thisPath, 'Z_indeces.txt');
	else
		instrs_file = fullfile(thisPath, varargin{1});
		Z_file = varargin{2};
	end
	scriptName = fullfile(thisPath, 'random_update_Z.py');
	[status, result] = system(sprintf('python "%s" "%s" "%s" "%s"', scriptName, seq_file, instrs_file, Z_file), '-echo');
end
