aps = deviceDrivers.APS();
aps.open(0,1);
if ~aps.is_open
    error('Fail')
end
aps.stop();
forceLoadBitFile = 0;
aps.init(forceLoadBitFile);

ramp = int32(0:2:8190);
for i = 0:3, aps.loadWaveform(i, ramp); end

i = 1;
max_iterations = 20;
done = 0;

while ~done && i < max_iterations
    aps.triggerFpga(0, aps.TRIGGER_HARDWARE);
    aps.triggerFpga(2, aps.TRIGGER_HARDWARE);
    keyboard
    aps.stop();
    if ~done
        aps.init(1);
    end
    i = i + 1;
end

aps.close();
delete(aps); clear aps