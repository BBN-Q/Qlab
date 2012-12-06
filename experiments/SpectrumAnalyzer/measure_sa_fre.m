sa = deviceDrivers.SpectrumAnalyzer();
sa.connect('COM18');

% hprf=deviceDrivers.HP8673B();
% hprf.connect('19');
% hprf.power= -40;
% hprf.output= 1;
agrf=deviceDrivers.AgilentN5183A();
agrf.connect('11');
agrf.power= 0;
agrf.output= 1;

aglo=deviceDrivers.AgilentN5183A();
aglo.connect('10');
aglo.power= 7;
aglo.output= 1;

pause(5)

clear dacval
dacval=zeros(1,51);
freqs = linspace(2.5, 9, 51);
for i=1:length(freqs)
    agrf.frequency= freqs(i)+0.0107;
    aglo.frequency= freqs(i);
    rawVal = sa.getVoltage();
    while isempty(rawVal), rawVal = sa.getVoltage(); end
    dacval(i)=str2double(rawVal);
    i
    dacval(i)
    pause(1)
    plot(freqs(1:i),dacval(1:i))
end
agrf.output= 0;
aglo.output= 0;
sa.disconnect();
agrf.disconnect();
aglo.disconnect();