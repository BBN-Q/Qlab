function exportAPSConfig(path, basename, nbrRepeats, varargin)
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
    
    miniLinkRepeat = nbrRepeats - 1;
    WaveformLibs = cell(1,4);
    LinkLists = cell(1,4);
    
    for ct = 1:length(varargin)
        Ich = 2*ct-1;
        Qch = 2*ct;
        if ~isempty(varargin{ct})
            seq = varargin{ct};
            [xWfLib, yWfLib] = APSPattern.buildWaveformLibrary(seq, useVarients);
            [WaveformLibs{Ich}, xbanks] = APSPattern.convertLinkListFormat(seq, useVarients, xWfLib, miniLinkRepeat);
            [WaveformLibs{Qch}, ybanks] = APSPattern.convertLinkListFormat(seq, useVarients, yWfLib, miniLinkRepeat);

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
    
    %First create it with overwrite if it is there
    tmpFID = H5F.create(fileName,'H5F_ACC_TRUNC', H5P.create('H5P_FILE_CREATE'),H5P.create('H5P_FILE_ACCESS'));
    H5F.close(tmpFID);
    
    %Version number
    h5writeatt(fileName,'/', 'Version', VersionNum);

    %And then specify which channels we have data for
    h5writeatt(fileName, '/', 'channelDataFor', channelDataFor);

    %Now create each channel group and put the associated data
    for channel = channelDataFor
        channelStr = sprintf('/chan_%d', channel);
        
        %The waveform library
        h5create(fileName, [channelStr, '/waveformLib'], size(WaveformLibs{channel}), 'Datatype', 'int16');
        h5write(fileName, [channelStr, '/waveformLib'], WaveformLibs{channel});
        
        %An attribute whether there is LinkList data specified
        h5writeatt(fileName, channelStr, 'isLinkListData', uint16(LinkLists{channel}.numBanks > 0));
        
        %Now loop over each bank
        for bankct = 1:LinkLists{channel}.numBanks
            bankStr = sprintf('bank%d',bankct);
            curBank = LinkLists{channel}.(bankStr);
            groupStr = [channelStr, '/linkListData/', bankStr];
            bankLength = double(curBank.length);
            h5create(fileName, [groupStr, '/offset'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/offset'], curBank.offset);
            h5create(fileName, [groupStr, '/count'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/count'], curBank.count);
            h5create(fileName, [groupStr, '/trigger'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/trigger'], curBank.trigger);
            h5create(fileName, [groupStr, '/repeat'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/repeat'], curBank.repeat);
            h5writeatt(fileName, groupStr, 'length', uint16(bankLength));
        end
        
        %Then the number of banks
        h5writeatt(fileName, [channelStr, '/linkListData'], 'numBanks',  uint16(LinkLists{channel}.numBanks));
        
        %Finally the repeatCount
        h5writeatt(fileName, [channelStr, '/linkListData'], 'repeatCount',  uint16(LinkLists{channel}.repeatCount));
    end
end