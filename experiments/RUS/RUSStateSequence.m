function RUSStateSequence(ancilla, data, psi0, delay, shift, phc)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'RUSStateSequence.py');
system(sprintf('python "%s" "%s" %s %s %s %f %f %f', scriptName, getpref('qlab', 'PyQLabDir'), ancilla, data,...
    psi0, delay, shift, phc), '-echo');

end



% parser = argparse.ArgumentParser()
% parser.add_argument('ancilla', help='ancilla qubit')
% parser.add_argument('data', help='data qubit')
% parser.add_argument('pyqlabpath', help='path to PyQLab directory')
% parser.add_argument('psi0', help='initial state')
% parser.add_argument('delay', help='delay after measurement')
% parser.add_argument('shift', help='shift of echo pulse relative to the measurement center')
% parser.add_argument('phc', help='phase correction on data qubit')
