function SingleShotFidelityDo(obj)

obj.experiment.run();

% pull out data from the SingleShot measurement filter
histData = obj.experiment.measurements.single_shot.histData;


figure()
subplot(2,1,1)
cla()
groundBars = bar(histData.bins_amp, histData.groundCounts_amp, 'histc');
set(groundBars, 'FaceColor','r','EdgeColor','w')
alpha(groundBars,0.5)
hold on
excitedBars = bar(histData.bins_amp, histData.excitedCounts_amp, 'histc');
set(excitedBars, 'FaceColor','b','EdgeColor','w')
alpha(excitedBars,0.5)
legend({'ground','excited'})
xlabel('Measurement Voltage');
ylabel('Counts');
text(0.1, 0.75, sprintf('Fidelity: %.1f%%',100*histData.maxFidelity_amp), 'Units', 'normalized', 'FontSize', 14)

subplot(2,1,2)
cla()
groundBars = bar(histData.bins_phase, histData.groundCounts_phase, 'histc');
set(groundBars, 'FaceColor','r','EdgeColor','w')
alpha(groundBars,0.5)
hold on
excitedBars = bar(histData.bins_phase, histData.excitedCounts_phase, 'histc');
set(excitedBars, 'FaceColor','b','EdgeColor','w')
alpha(excitedBars,0.5)
legend({'ground','excited'})
xlabel('Measurement Voltage');
ylabel('Counts');
text(0.1, 0.75, sprintf('Fidelity: %.1f%%',100*histData.maxFidelity_phase), 'Units', 'normalized', 'FontSize', 14)

end
