function fftScope()

%setup the scope
scope = deviceDrivers.AlazarATS9870();
scope.connect(0);
samplingRate = 100e6;
recordLength = 6400;

scope.horizontal = struct('samplingRate', samplingRate, 'delayTime', 0);
scope.vertical = struct('verticalScale', 0.2, 'verticalCoupling', 2, 'bandwidth', 0);
scope.trigger = struct('triggerLevel', 500, 'triggerSource', 2, 'triggerCoupling', 2, 'triggerSlope', 0);
scope.averager = struct('recordLength', recordLength, 'nbrSegments', 1, 'nbrWaveforms', 1, 'nbrRoundRobins', 1, 'ditherRange', 0);

running = true;
figure();
xpts = linspace(0, samplingRate/2, recordLength/2+1);
% skip DC term
h = plot(xpts(2:end), nan(1, recordLength/2));
set(gca(), 'YLimMode', 'manual');
set(gca(), 'YLim', [0, 35]);

while (running)
    scope.acquire();
    scope.wait_for_acquisition(1);
    [wfm, ~] = scope.transfer_waveform(1);
    y = fft(wfm);
    
    % skip DC term
    set(h, 'YData', abs(y(2:recordLength/2+1)));
    
    % check for quit
    k=get(gcf,'currentkey');
    if (k == 'x')
        running = false;
    end
    pause(.1);
end

scope.disconnect();

end