numPts = 1000;
writeVals = randi([0, 8191], [1, numPts], 'uint16');
% writeVals = randi(2, [1, numPts], 'uint16') - 1;
% writeVals = int16(0:999);
%Write the test waveform
dataStream = APSDataFormatter(writeVals, bitshift(1,28)+0);
calllib('libaps', 'raw_write', 3, length(dataStream), dataStream);
% aps.loadWaveform(1, writeVals);

%Test the points by reading them out
testIndices = randperm(numPts);
readVals = zeros([1, numPts], 'uint16');
for ct = 1:numPts
    curIndex = testIndices(ct);
    %Create the read address byte stream
    readVals(curIndex) = aps.readRegister(2,bitshift(1,28)+curIndex-1);
end

% readVals = int16(readVals);
% readVals(readVals>8191) = readVals(readVals>8191)-16384;

percentCorrect = sum(readVals == writeVals)/numPts;

fprintf('%.0f%% waveform values read/write matches.\n', 100*percentCorrect);


% for stopct = 1:numPts
%     dataStream = APSDataFormatter(writeVals(1:stopct), bitshift(1,28)+0);
%     calllib('libaps64', 'raw_write', 0, length(dataStream), dataStream);
%     lastPoint = aps.readRegister(1, bitshift(1,28)+stopct-1);
%     lastPointReg = aps.readRegister(1, 20);
% %     fprintf('Tried to write: %d; Memory Read: %d; LastPointReg: %d', writeVals(stopct), lastPoint, lastPointReg);
%     if (lastPointReg ~= writeVals(stopct))
%         fprintf('   Oops!! Problem with last point register!\n');
%     elseif (lastPoint ~= writeVals(stopct))
%         fprintf('   Oops!! Problem with last point memory!\n');
%     else
% %         fprintf('\n');
%     end
% end

    