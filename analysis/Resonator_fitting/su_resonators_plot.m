rindex = 5; % which resonator do you want to look at?
throwaway = 0; % # of temperatures to ignore

%data points per sweep
points=data{rindex}{1}.CFG.InitParams.pna.ordered.sweep_points;

%center frequncy of PNA scan (Hz)
cfreq=data{rindex}{1}.CFG.ExpParams.meas_resp.sweep_center.start;

%span of PNA scan (Hz)
span=data{rindex}{1}.CFG.InitParams.pna.ordered.sweep_span;

% define frequency range
frequency=linspace(cfreq-span/2,cfreq+span/2,points);

figure
colors = colormap(jet(length(temperatures)-throwaway));

for i = 1:(length(temperatures)-throwaway)
    reald = data{rindex}{i}.Data(1:2:end);
    imagd = data{rindex}{i}.Data(2:2:end);
    magd = sqrt(reald.^2 + imagd.^2);
    plot(frequency, magd, 'Color', colors(i,:))
    hold on
    
    labels{i} = sprintf('%g K', temperatures(i));
end

title(sprintf('Resonator %d', rindex))
xlabel('Frequency [Hz]')
ylabel('Magnitude of S21')
l = legend(labels, 'Location', 'SouthWest');
set(l, 'Box', 'off')
axis tight
hold off