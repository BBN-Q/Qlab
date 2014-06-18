function exportAPSConfig(path, basename, nbrRepeats, varargin)
    %varargin is the IQ pairs of channels e.g. ch56seq
    %pass an empty array to skip a pair of channels
    VersionNum = 2;
        
    % construct filename
    % disp('Writing APS file');
    fileName = strcat(path, basename, '.h5');
    if ~exist(path, 'dir')
        mkdir(path);
    end
    
    miniLLRepeat = nbrRepeats - 1;
    WaveformLibs = cell(1,4);
    LinkLists = cell(1,4);
    
    for ct = 1:length(varargin)
        Ich = 2*ct-1;
        Qch = 2*ct;
        if ~isempty(varargin{ct})
            seq = varargin{ct};
            [LinkLists{Ich}, WaveformLibs{Ich}, WaveformLibs{Qch}] = APSPattern.convertLinkListFormat(seq);

            %Setup the structures for the linkList data
            fprintf('Length of LL for pair %d: %d\n', ct, LinkLists{Ich}.length)
            LinkLists{Qch} = [];
            if LinkLists{Ich}.length > APSPattern.MAX_LL_ENTRIES
                if getpref('Qlab','reliable_aps')
                    error('Linked list too long; max is %d\n', APSPattern.MAX_LL_ENTRIES);
                end
                fprintf('Estimated max rep interval: %g\n', APSPattern.estimateRepInterval(seq.linkLists));
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
    
    %An attribute for the miniLL repeat count
    h5writeatt(fileName, '/', 'miniLLRepeat', uint16(miniLLRepeat));

    %Now create each channel group and put the associated data
    for channel = channelDataFor
        channelStr = sprintf('/chan_%d', channel);
        
        %The waveform library
        h5create(fileName, [channelStr, '/waveformLib'], size(WaveformLibs{channel}), 'Datatype', 'int16');
        h5write(fileName, [channelStr, '/waveformLib'], WaveformLibs{channel});
        
        %An attribute whether there is LinkList data specified
        isLLData = ~isempty(LinkLists{channel});
        h5writeatt(fileName, channelStr, 'isLinkListData', uint8(isLLData));
        
        %An attribute whether there is LinkList data specified
        h5writeatt(fileName, channelStr, 'isIQMode', uint8(1));
        
        if isLLData
            %Write out the LL data
            groupStr = [channelStr, '/linkListData/'];
            bankLength = double(LinkLists{channel}.length);
            h5create(fileName, [groupStr, '/addr'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/addr'], LinkLists{channel}.addr);
            h5create(fileName, [groupStr, '/count'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/count'], LinkLists{channel}.count);
            h5create(fileName, [groupStr, '/trigger1'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/trigger1'], LinkLists{channel}.trigger1);
            h5create(fileName, [groupStr, '/trigger2'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/trigger2'], LinkLists{channel}.trigger2);
            h5create(fileName, [groupStr, '/repeat'], [1, bankLength], 'Datatype', 'uint16');
            h5write(fileName, [groupStr, '/repeat'], LinkLists{channel}.repeat);
            h5writeatt(fileName, groupStr, 'length', uint16(bankLength));

        end
    end
    
end