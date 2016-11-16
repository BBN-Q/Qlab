function pauli_frame_update(seq_file, gst_file, seq_ind, varargin)
% modify Z gates in DiAC pulses in a pre-compiled GST sequence seq_file. Use pre-randomized sequences zipped in gst_file. Seq_ind is the index
% of the pre-randomized sequence
% Instructions:
% - generate a GST seq. with DiAC pulses with compiled = False. Make sure that every pulse has non-zero Z gates to generate the template for the
%   in-place frame updates.
% - in QGL, save instructions and location of the Z gates using save_frame_instrs(seq_loc,'C:\\Users\\qlab\\Documents\\GitHub\\Qlab\\experiments\\GST')
% - run pauli_frame_update before taking single-shot data for every seq_ind 
	[thisPath, ~] = fileparts(mfilename('fullpath'));
	if isempty(varargin)
		instrs_file = fullfile(thisPath, 'GST_1q_Z.pickle');
	else
		instrs_file = fullfile(thisPath, varargin{1});
	end
	scriptName = fullfile(thisPath, 'pauli_frame_update.py');
	[status, result] = system(sprintf('python "%s" "%s" "%s" "%s" %d', scriptName, seq_file, instrs_file, gst_file, seq_ind), '-echo');
end
