function T1T2series(qubitlist, nloops)
%running T1, T2 sequences for different qubits in a loop
% qubitlist, e.g. {'q1','q3','q5'};
% nloops: number of repeats

doT1 = true;
doRamsey = true;
doSeqs = true; %generate the seqs

T1Stop = 200e3; T1Step = 2000;
RamseyStop = 80e3; RamseyStep = 800;

if doSeqs
    [thisPath, ~] = fileparts(mfilename('fullpath'));
    for q = 1:length(qubitlist)
        if doT1
            scriptName = fullfile(thisPath, 'T1Sequence.py');
            system(sprintf('python "%s" "%s" %s %d %d', scriptName, getpref('qlab', 'PyQLabDir'), qubitlist{q}, T1Stop, T1Step), '-echo');
        end
        if doRamsey
            scriptName = fullfile(thisPath, 'RamseySequence.py');
            system(sprintf('python "%s" "%s" %s %d %d', scriptName, getpref('qlab', 'PyQLabDir'), qubitlist{q}, RamseyStop, RamseyStep), '-echo');
        end
    end
end

for k = 1:nloops

    for q = 1:length(qubitlist)
        warning('off', 'json:fieldNameConflict');
        chanSettings = json.read(getpref('qlab', 'ChannelParamsFile'));
        expSettings = json.read(getpref('qlab', 'CurScripterFile'));
        instrSettings = expSettings.instruments;
        warning('on', 'json:fieldNameConflict');
        
        chanSettings = chanSettings.channelDict;
        
        expSettings.AWGs = {'APSII4'}; %master AWG
        
        qubit = qubitlist{q}
        %select the relevant AWGs
        tmpStr = regexp(chanSettings.(qubit).physChan, '-', 'split');
        expSettings.AWGs{2} = tmpStr{1};
        tmpStr = regexp(chanSettings.(strcat(genvarname('M-'),qubit)).physChan, '-', 'split');
        expSettings.AWGs{3} = tmpStr{1};
        expSettings.AWGs = unique(expSettings.AWGs); %remove duplicates
        
        %add the relevant meas filters and sources
        measSettings = {};
        mstr = strcat('M',qubit(2),'Kernel');
        measSettings.(mstr) = expSettings.measurements.(mstr);
        dataSource = expSettings.measurements.(mstr).dataSource;
        for m=1:3
            %recursively add sources (measurements or instruments)
            if (~isempty(strfind(dataSource, 'X6')) || ~isempty(strfind(dataSource, 'ATS'))) 
                for instrName = fieldnames(expSettings.instruments)'
                    if ((~isempty(strfind(instrName{1}, 'X6')) || ~isempty(strfind(instrName{1}, 'ATS'))) && ~strcmp(dataSource, instrName{1}))
                        expSettings.instruments = rmfield(expSettings.instruments, instrName{1});
                    end
                end
                break
            elseif isfield(expSettings.measurements.(dataSource), 'dataSource')
                measSettings.(dataSource) = expSettings.measurements.(dataSource);
                dataSource = expSettings.measurements.(dataSource).dataSource;
            else
                break
            end
        end
        expSettings.measurements = measSettings;
        
        if doT1
            expSettings.AWGfilename = strcat('T1_', qubit);
            expSettings.sweeps.SegmentNumWithCals.start = 0;
            expSettings.sweeps.SegmentNumWithCals.stop = T1Stop;
            expSettings.sweeps.SegmentNumWithCals.step = T1Step;
            ExpScripter2(strcat('T1_',qubit), 'lockSegments', expSettings);
        end
        
        if doRamsey
            expSettings.AWGfilename = strcat('Ramsey_', qubit);
            expSettings.sweeps.SegmentNumWithCals.start = 0;
            expSettings.sweeps.SegmentNumWithCals.stop = RamseyStop;
            expSettings.sweeps.SegmentNumWithCals.step = RamseyStep;
            ExpScripter2(strcat('Ramsey_',qubit), 'lockSegments', expSettings);
        end
    end

end
