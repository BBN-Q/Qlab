function T1T2series(qubitlist, numRepeats)
%running T1, T2 sequences on multiple qubits
%qubitlist = {'q1', 'q2', ...}

for k=1:numRepeats

    for q = 1:length(qubitlist)
        warning('off', 'json:fieldNameConflict');
        chanSettings = json.read(getpref('qlab', 'ChannelParamsFile'));
        expSettings = json.read(getpref('qlab', 'CurScripterFile'));
        instrSettings = expSettings.instruments;
        warning('on', 'json:fieldNameConflict');
        
        chanSettings = chanSettings.channelDict;
        
        expSettings.AWGs = {'BBNAPS2'}; %master AWG
        
        qubit = qubitlist{q}
        %selects the relevant AWGs
        tmpStr = regexp(chanSettings.(qubit).physChan, '-', 'split');
        expSettings.AWGs{2} = tmpStr{1};
        tmpStr = regexp(chanSettings.(strcat(genvarname('M-'),qubit)).physChan, '-', 'split');
        expSettings.AWGs{3} = tmpStr{1};
        expSettings.AWGs = unique(expSettings.AWGs); %remove duplicates

        expSettings.AWGfilename = strcat('T1_', qubit);
        expSettings.sweeps.SegmentNumWithCals.start = 0;
        expSettings.sweeps.SegmentNumWithCals.stop = 100000;
        expSettings.sweeps.SegmentNumWithCals.step = 1000;
        for measname = fieldnames(expSettings.measurements)'
            if sum(strfind(measname{1},strcat('M',qubit(2))))==0 && ~isempty(strfind(measname{1},'M'))
                expSettings.measurements = rmfield(expSettings.measurements, measname{1});
            end
        end
        ExpScripter2(strcat('T1_',qubit), 'lockSegments', expSettings);
        
        expSettings.sweeps.SegmentNumWithCals.start = 0;
        expSettings.sweeps.SegmentNumWithCals.stop = 80000;
        expSettings.sweeps.SegmentNumWithCals.step = 800;
        expSettings.AWGfilename = strcat('Ramsey_', qubit);
        ExpScripter2(strcat('Ramsey_',qubit), 'lockSegments', expSettings);
        
    end

end
