function simpleTekUpload(channel, waveform, marker1, marker2)
    % function simpleTekUpload
    % channel - Tek channel to write to (integer 1-4)
    % waveform - analog data
    % marker 1 - binary marker 1 data
    % marker 2 - binary marker 2 data
    
    data = TekPattern.packPattern(waveform, marker1, marker2);
    
    % pack waveform by separating waveform values into (low-8, high-8)
    % sequential values, aka LSB format
    bindata = zeros(2*length(data),1);
    bindata(1:2:end) = bitand(data,255);
    bindata(2:2:end) = bitshift(data,-8);
    bindata = bindata';

    % connect
    address = '128.33.89.94';
    port = 4000;
    awg = tcpip(address, port);
    set(awg, 'OutputBufferSize', 1000000);
    
    % write
    wname = ['ch' num2str(channel)];
    fwrite(awg, [':wlist:waveform:del "' wname '";']);
    fwrite(awg,[':wlist:waveform:new "' wname '",' num2str(length(waveform)) ',integer;']);
    binblockwrite(awg, bindata, [':wlist:waveform:data "' wname '",']); %data transmission
    fwrite(awg, ';');
    fwrite(awg,[':source1:waveform "' wname '";']);
    
    % connect
    fclose(awg);
    delete(awg);
    clear(awg);
end