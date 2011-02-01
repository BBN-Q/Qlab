function residue = calculateResidue_cQEDsim(params,Frequency,SimParameters,Constants)

numPoints = numel(Frequency);

fitParameters.Ic        = params(1);
fitParameters.Cq        = params(2);
fitParameters.alpha     = params(3);
fitParameters.CsdCj     = params(4); %ratio of C_shunt to C_josephson, dimensionless
fitParameters.g         = params(5); % Hz
fitParameters.f_r       = params(6); % Hz

SimParameters.Phi_min   = params(7); %in units of Phi0
SimParameters.Phi_max   = params(8); %in units of Phi0

output = simulateCQEDqubit(fitParameters,SimParameters,Constants);
numFreqs = size(output.JCFrequencies,1);
frequency_diff = abs(1e-9*output.JCFrequencies - repmat(Frequency,[numFreqs,1]));
[temp_row temp_column] = find(frequency_diff == repmat(min(frequency_diff),[numFreqs,1]));

simFrequencies = zeros(1,numPoints);
for Phi_i = 1:numPoints
    simFrequencies(Phi_i) = 1e-9*output.JCFrequencies(temp_row(Phi_i),temp_column(Phi_i));
end

residue = sum((Frequency-simFrequencies).^2)/numPoints;

end