function CLEARCalSequence(qubit, meas_qubit, ramsey_stop, npoints, ramsey_freq, delay, eps1, eps2, tau, state)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'CLEARCal.py');
system(sprintf('python "%s" "%s" "%s" %f %d %f %.3f %f %f %.3f %d', scriptName, qubit, meas_qubit, ramsey_stop, npoints, ramsey_freq, delay, eps1, eps2, tau, state), '-echo');
end