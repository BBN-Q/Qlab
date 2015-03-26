function results = field_sweep(fieldScan, bop, srs)

results = nan(length(fieldScan),1);

figure();
plotHandle = scatter(fieldScan, results, [],  [zeros(length(fieldScan)/2,1); ones(length(fieldScan)/2,1)], 'filled');
xlabel('Current (A)');
ylabel('Relative Voltage (V)');

% slow ramp of bop to start  current
ramp(bop,fieldScan(1),50);

for ct = 1:length(fieldScan)
    %Set the current
    bop.value = fieldScan(ct);

    %Wait to settle
    pause(1);

    %Read the value
    results(ct) = srs.R;
    set(plotHandle, 'YData', results);
end

%  slow rampdown of bop back to zero
ramp(bop,0,50);

end
