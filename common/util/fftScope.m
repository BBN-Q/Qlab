function fftScope()

%setup the scope
scope = deviceDrivers.AlazarATS9870();
scope.connect(0);
samplingRate = 500e6;
recordLength = 8192;

scope.horizontal = struct('samplingRate', samplingRate, 'delayTime', 0);
scope.vertical = struct('verticalScale', 0.04, 'verticalCoupling', 'AC', 'bandwidth', 'Full');
scope.trigger = struct('triggerLevel', 100, 'triggerSource', 'ext', 'triggerCoupling', 'DC', 'triggerSlope', 'rising');
scope.averager = struct('recordLength', recordLength, 'nbrSegments', 1, 'nbrWaveforms', 1, 'nbrRoundRobins', 10000, 'ditherRange', 0);

running = true;
figure();
freqs = [0:1:recordLength/2-1, -recordLength/2:1:-1] * (samplingRate/recordLength);
% skip DC term
h = plot(freqs(2:end/2), nan(1, recordLength/2 - 1));
% set(gca(), 'YLimMode', 'manual');
% set(gca(), 'YLim', [0, 35]);

while (running)
    scope.acquire();
    scope.wait_for_acquisition(1);
    [wfm, ~] = scope.transfer_waveform(1);
    y = fft(wfm);
    
    % skip DC term
    set(h, 'YData', abs(y(2:recordLength/2)));
    
    % check for quit
    k=get(gcf,'currentkey');
    if (k == 'x')
        running = false;
    end
    pause(.1);
end

scope.disconnect();

end