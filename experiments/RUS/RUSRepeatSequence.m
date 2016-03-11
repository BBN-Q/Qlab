function RUSRepeatSequence(ancilla, data, delay, shift, phc, ngates, Fb)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'RUSRepeatSequence.py');
system(sprintf('python "%s" "%s" %s %s %f %f %f %d %d', scriptName, getpref('qlab', 'PyQLabDir'), ancilla, data,...
    delay, shift, phc, ngates, Fb), '-echo');

end

% parser = argparse.ArgumentParser()
% parser.add_argument('pyqlabpath', help='path to PyQLab directory')
% parser.add_argument('ancilla', help='ancilla qubit')
% parser.add_argument('data', help='data qubit')
% parser.add_argument('delay', type=float, help='delay after measurement')
% parser.add_argument('shift', type=float, help='shift of echo pulse relative to the measurement center')	
% parser.add_argument('phc', type=float, help='phase correction on data qubit') %
% parser.add_argument('ngates', type=int, help='number of RUS gates')
% parser.add_argument('Fb', type=bool, help='feedback on or off')

