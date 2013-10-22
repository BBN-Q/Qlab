%% Hacky H field sweep

%% Setup instruments

bop = deviceDrivers.KepcoBOP();
bop.connect(1);
bop.mode = 'current';
bop.limit = 'MAX';
bop.output = true;

srs = deviceDrivers.SRS830();
srs.connect(8);

yoko = deviceDrivers.YokoGS200();
yoko.connect(2);

ppl = deviceDrivers.Picosec10070A();
ppl.connect(5);

%% Field only

%Ramp from start to end and back to start
startCur=-20;
endCur=20;
steps=100;
fieldScan = [linspace(startCur,endCur,steps), linspace(endCur,startCur,steps)];

signal = nan(length(fieldScan),1);

figure();
plotHandle = scatter(fieldScan, signal, [],  [zeros(steps,1); ones(steps,1)], 'filled');
xlabel('Current (A)');
ylabel('Relative Voltage (V)');
% slow ramp of bop to start  current
ramp(bop,startCur,50);

for ct = 1:length(fieldScan)
    %Set the current
    bop.value = fieldScan(ct);
    %Wait to settle
    pause(1);

    %Read the value
    signal(ct) = srs.R;
    set(plotHandle, 'YData', signal);
end
%  slow rampdown of bop back to zero
ramp(bop,0,50);

%% Current only

curScan = [linspace(0e-3, 3e-3, 40),linspace(3e-3,-3e-3, 80),linspace(-3e-3,0e-3, 40)];
signal = nan(length(curScan),1);

    Bval=7.5;
    figure();
    plotHandle = plot(curScan, signal, '*');
    xlabel('Current (A)');
    ylabel('Relative Voltage (V)');
   %slow ramp of bop
%     for ct=1:Bval
%         bop.value = -ct;
%         pause(1)
%     end
    endCur=7.5;
     %bop.value = -4;
     bop.value = endCur;
     yoko.value = 0e-3;
     pause(3)
    for ct2 = 1:length(curScan)
        %Set the current
        yoko.value = curScan(ct2);
        %Wait to settle
        pause(3);
        
        %Read the value
        [~,~,signal(ct2),~] = srs.get_signal();
        set(plotHandle, 'YData', signal);
    end
   %  slow rampdown of bop
%     for ct=1:round(abs(endcur))
%         bop.value = (round(endcur)+ct);
%         pause(1)
%     end
    
    %% field only with pulsing
maxCur=0;
prebiascur1=3;
prebiascur2=4;
biascur=4.4;
%endcur=-3;
steps=40;
amps=linspace(2,-2,steps);
durs=[1 .9 .8 .7];
%fieldScan = [linspace(startcur,endcur,steps), linspace(endcur,startcur,steps)];
finmaxCur=biascur;
signal = nan(length(amps),1);
%ppl.duration = 2E-9;
    yoko.value = 0E-3;
    figure();
    %plotHandle = scatter(amps, signal, [],  [zeros(steps,1); ones(steps,1)]);
    plotHandle = plot(amps, signal, '*');
    xlabel('Amp (V)');
    ylabel('Relative Voltage (V)');
   % slow ramp of bop to maximum negative current
    for ct=1:maxCur
        bop.value = -ct;
        pause(1)
    end
%     bop.value = -maxCur;
%         pause(2)
%         bop.value = prebiascur1;
%         pause(2)
%         bop.value = prebiascur2;
%         pause(2)
%         bop.value = biascur;
%         pause(3)
    
for ct1=1:length(durs)
    ppl.duration= str2num(sprintf('%sE-9',num2str(durs(ct1))));
    for ct = 1:length(amps)
        %set bop bias
        bop.value = -maxCur;
        pause(2)
        bop.value = prebiascur1;
        pause(2)
        bop.value = prebiascur2;
        pause(2)
        bop.value = biascur;
        pause(3)
        %Set the current minor loop bias point
        ppl.amplitude = amps(ct);
        ppl.trigger()
%         pause(1)
%         ppl.trigger()
        %amp(ct)
        %Wait to settle
        pause(3);
        %Read the value
        [~,~,signal(ct,ct1),~] = srs.get_signal();
        set(plotHandle, 'YData', signal(:,ct1));
%         if signal(ct)>-1e-5
%         ppl.trigger()
%         pause(3);
%         else
%         end
    end
end

   %  slow rampdown of bop back to zero
    for ct=1:round(abs(finmaxCur))
        bop.value = (round(finmaxCur)+(1-ct));
        pause(1)
    end