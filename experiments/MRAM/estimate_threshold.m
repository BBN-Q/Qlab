function threshold = estimate_threshold(fieldScan, bop, srs)
%threshold = estimate_threshold(fieldScan, bop, srs)
%
% Estimate the threshold by taking a field sweep and calculating the
% mid-points of the P and AP voltages.

%First run the field sweep

results = field_sweep(fieldScan, bop, srs);

meanP = mean([results(1:10) ; results(end-10:end)]);
meanAP = mean(results(end/2-10:end/2+10));

threshold = 0.5*(meanP + meanAP);

end
