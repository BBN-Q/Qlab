function dataStream = APSDataFormatter(wf, startAddress)

wfLength = length(wf);

LSB = hex2dec('FF');

fpgaSel = uint8(2); % 1, 2, or 3 (3 = both)
fpgaSelectMask = bitshift(fpgaSel, 2);
writeCommand1Byte = bitor(0, fpgaSelectMask);
writeCommand2Bytes = bitor(1, fpgaSelectMask);
writeCommand4Bytes = bitor(2, fpgaSelectMask);
writeCommand8Bytes = bitor(3, fpgaSelectMask);

dataStream = zeros(0, 'uint8');

%Push on the address 4 bytes worth
dataStream = [dataStream, bitset(writeCommand4Bytes,5)];
dataStream = [dataStream, uint8(bitand(bitshift(startAddress,-24), LSB))];
dataStream = [dataStream, uint8(bitand(bitshift(startAddress,-16), LSB))];
dataStream = [dataStream, uint8(bitand(bitshift(startAddress,-8), LSB))];
dataStream = [dataStream, uint8(bitand(startAddress, LSB))];

%Push on the number of words
if(~isempty(wf))
    dataStream = [dataStream, writeCommand2Bytes];
    dataStream = [dataStream, uint8(bitand(bitshift(wfLength, -8), LSB))];
    dataStream = [dataStream, uint8(bitand(wfLength, LSB))];
    %Push on the data
    ptsRemaining = wfLength;
    wfIndex = 1;
%     ptsToWrite = 1;
    while (ptsRemaining >0)
        if ptsRemaining >= 4
            dataStream = [dataStream, writeCommand8Bytes];
            ptsToWrite = 4;
        else
            switch ptsRemaining
                case {2, 3}
                    dataStream = [dataStream, writeCommand4Bytes];
                    ptsToWrite = 2;
                case 1
                    dataStream = [dataStream, writeCommand2Bytes];
                    ptsToWrite = 1;
            end
        end
    
        for ct = 1:ptsToWrite
            dataStream = [dataStream, uint8(bitand(bitshift(wf(wfIndex),-8), LSB))];
            dataStream = [dataStream, uint8(bitand(wf(wfIndex), LSB))];
            wfIndex = wfIndex+1;
        end
        ptsRemaining = ptsRemaining - ptsToWrite;
    end
end
