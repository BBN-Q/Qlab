sa = deviceDrivers.SpectrumAnalyzer();
sa.connect('COM18');

hprf=deviceDrivers.HP8673B();
hprf.connect('19');
hprf.frequency= 7.5107;
hprf.output= 1;

aglo=deviceDrivers.AgilentN5183A();
aglo.connect('10');
aglo.frequency= 7.5000;
aglo.power= 7;
aglo.output= 1;

pause(5)

clear dacval
dacval=zeros(1,11);
powers = linspace(-100, 10, 51);
for i=1:length(powers)
    hprf.power= powers(i);
    rawVal = sa.getVoltage();
    while isempty(rawVal), rawVal = sa.getVoltage(); end
    dacval(i)=str2double(rawVal);
    i
    dacval(i)
    pause(1)
    plot(powers(1:i)-20,dacval(1:i))
end
hprf.output= 0;
aglo.output= 0;
sa.disconnect();
hprf.disconnect();
aglo.disconnect();
 
 