function bestParam = analyzeSlopes(data, numPsQId, paramRange)

%Assume that we have nbrRepeats = 1 for now
nbrRepeats = 1;
data = mean(reshape(data,nbrRepeats,[]),1);

%Add one for the first 90 only experiment
numPsQId = numPsQId+1;

groundCal = mean(data(1:numPsQId+1:end-1));
excitedCal = data(end);

scaledData = (data-groundCal)/(excitedCal-groundCal);
varEstimate = var(scaledData(1:numPsQId+1:end-1));
figure;
h = axes();
plot(h, 1:length(scaledData), scaledData); hold on;

numParams = length(paramRange); %number of drag parameters (11)
slopes = zeros(numParams,1);
for ct = 1:numParams
    %Pull out the data
    tmpData = scaledData((ct-1)*(numPsQId+1)+2:ct*(numPsQId+1));
    
    %Fit to a linear model
    fitResult = polyfit(1:numPsQId, tmpData, 1);
    
    %Create the fitted values and plot
    fitYs = fitResult(1)*(1:numPsQId) + fitResult(2);
    plot(h, (ct-1)*(numPsQId+1)+2:ct*(numPsQId+1), fitYs, 'r');

    %Sort out whether the fit was any good and use the Rsquared to filter
    sse = sum((fitYs-tmpData).^2);
    Rsquared = (sse/varEstimate)/(numPsQId-2);
    if abs(1-Rsquared) < 1.0
        slopes(ct) = fitResult(1);
    else
        slopes(ct) = nan;
    end
end

%Remove the bad fits 
goodFits = ~isnan(slopes);

fitResult = polyfit(paramRange(goodFits), slopes(goodFits),1);

bestParam = -fitResult(2)/fitResult(1);

end