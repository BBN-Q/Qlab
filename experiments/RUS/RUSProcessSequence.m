function RUSProcessSequence(ancilla, data, delay, shift, phc, RUScap, gateid)
%gateid = 0 for (I+isqrt(2)iX)/sqrt(3)
           %1 for (I + 2iZ)/sqrt(5)

[thisPath, ~] = fileparts(mfilename('fullpath'));
if gateid==0
    scriptName = fullfile(thisPath, 'RUSProcessSequenceV0.py');
else
    scriptName = fullfile(thisPath, 'RUSProcessSequence.py');
end
system(sprintf('python "%s" "%s" %s %s %f %f %f %d', scriptName, getpref('qlab', 'PyQLabDir'), ancilla, data,...
    delay, shift, phc, RUScap), '-echo');

end



% parser = argparse.ArgumentParser()
% parser.add_argument('ancilla', help='ancilla qubit')
% parser.add_argument('data', help='data qubit')
% parser.add_argument('pyqlabpath', help='path to PyQLab directory')
% parser.add_argument('psi0', help='initial state')
% parser.add_argument('delay', help='delay after measurement')
% parser.add_argument('shift', help='shift of echo pulse relative to the measurement center')
% parser.add_argument('phc', help='phase correction on data qubit')
