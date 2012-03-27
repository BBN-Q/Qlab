function exportAPSConfig(path, basename, varargin)
    %varargin is the IQ pairs of channels e.g. ch56seq
    %pass an empty array to skip a pair of channels
    VersionNum = 1.6;
    
    useVarients = 1;
    
    % construct filename
    disp('Writing APS file');
    fileName = strcat(path, basename, '.h5');
    if ~exist(path, 'dir')
        mkdir(path);
    end
    
    miniLinkRepeat = 0;
    WaveformLibs = cell(1,4);
    LinkLists = cell(1,4);
    
    for ct = 1:length(varargin)
        Ich = 2*ct-1;
        Qch = 2*ct;
        if ~isempty(varargin{ct})
            seq = varargin{ct};
            [xWfLib, yWfLib] = APSPattern.buildWaveformLibrary(seq, useVarients);
            [wf, xbanks] = APSPattern.convertLinkListFormat(seq, useVarients, xWfLib, miniLinkRepeat);
            WaveformLibs{Ich} = wf.prep_vector();
            [wf, ybanks] = APSPattern.convertLinkListFormat(seq, useVarients, yWfLib, miniLinkRepeat);
            WaveformLibs{Qch} = wf.prep_vector();

            %Setup the structures for the linkList data
            LinkLists{Ich} = struct('repeatCount', 0);
            LinkLists{Qch} = struct('repeatCount', 0);
            LinkLists{Ich}.numBanks = length(xbanks);
            for bankct = 1:LinkLists{Ich}.numBanks
                bankStr = sprintf('bank%d',bankct);
                LinkLists{Ich}.(bankStr) = xbanks{bankct};
                fprintf('Length of Bank %d: %d\n', bankct, LinkLists{Ich}.(bankStr).length)
            end 
            LinkLists{Qch}.numBanks = length(ybanks);
            for bankct = 1:LinkLists{Qch}.numBanks
                LinkLists{Qch}.(sprintf('bank%d',bankct)) = ybanks{bankct};
            end 
        else
            WaveformLibs{Ich} = [];
            LinkLists{Ich} = [];
            WaveformLibs{Qch} = [];
            LinkLists{Ich} = [];
        end
    end
    
    %Figure out which channels have data
    channelDataFor = uint16(find(cellfun(@(x) ~isempty(x), WaveformLibs)));

    %Now write things out to the hdf5 file
    if exist(fileName, 'file')
        delete(fileName);
    end
    %First which channel we have data for
    h5create(fileName, '/channelDataFor', size(channelDataFor), 'Datatype', 'uint16');
    h5write(fileName, '/channelDataFor', channelDataFor);
    h5writeatt(fileName,'/', 'Version Number', VersionNum);
    %Now create each channel group and put the associated data
    for channel = channelDataFor
        channelStr = sprintf('/chan_%d', channel);
        
        %The waveform library
        h5create(fileName, [channelStr, '/waveformLib'], size(WaveformLibs{channel}), 'Datatype', 'int16');
        h5write(fileName, [channelStr, '/waveformLib'], WaveformLibs{channel});
        
        %The linklist data
        h5create(fileName, [channelStr, '/isLinkListData'], [1, 1], 'Datatype', 'uint16');
        h5write(fileName, [channelStr, '/isLinkListData'], uint16(LinkLists{channel}.numBanks > 0 ));
        
        %Then the number of banks
        h5create(fileName, [channelStr, '/linkListData/numBanks'], [1, 1], 'Datatype', 'uint16');
        h5write(fileName, [channelStr, '/linkListData/numBanks'], uint16(LinkLists{channel}.numBanks));

        %Now loop over each bank
        for bankct = 1:LinkLists{channel}.numBanks
            bankStr = sprintf('bank%d',bankct);
            curBank = LinkLists{channel}.(bankStr);
            groupStr = [channelStr, '/linkListData/', bankStr];
            bankLength = double(curBank.length);
            h5create(fileName, [groupStr, '/length'], [1, 1], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/length'], uint16(bankLength));
            h5create(fileName, [groupStr, '/offset'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/offset'], curBank.offset);
            h5create(fileName, [groupStr, '/count'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/count'], curBank.count);
            h5create(fileName, [groupStr, '/trigger'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/trigger'], curBank.trigger);
            h5create(fileName, [groupStr, '/repeat'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/repeat'], curBank.repeat);
        end
        
        %Finally the repeatCount
        h5create(fileName, [channelStr, '/linkListData/repeatCount'], [1, 1], 'Datatype', 'uint16');
        h5write(fileName, [channelStr, '/linkListData/repeatCount'], uint16(LinkLists{channel}.repeatCount));
        
        
    end
end