rindex = 3; % which resonator do you want to look at?

%data points per sweep
points=data{rindex}{1}.CFG.InitParams.pna.ordered.sweep_points;

%center frequncy of PNA scan (Hz)
cfreq=data{rindex}{1}.CFG.ExpParams.meas_resp.sweep_center.start;

%span of PNA scan (Hz)
span=data{rindex}{1}.CFG.InitParams.pna.ordered.sweep_span;

% define frequency range
frequency=linspace(cfreq-span/2,cfreq+span/2,points);


for i = 1:length(temperatures)
    reald = data{rindex}{i}.Data(1:2:end);
    imagd = data{rindex}{i}.Data(2:2:end);
    magd = sqrt(reald.^2 + imagd.^2);
    phased = (180/pi) * angle(complex(reald, imagd));
    
    filename = sprintf('resonator%d-%.2fK.txt', rindex, temperatures(i));
    clear fulldata
    fulldata(1,:) = frequency;
    fulldata(2,:) = magd;
    fulldata(3,:) = phased;
    fulldata = fulldata';
    
    dlmwrite(filename, fulldata, 'delimiter', '\t', 'precision', '%e')
end
