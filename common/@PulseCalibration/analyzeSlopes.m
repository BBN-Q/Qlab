function bestParam = analyzeSlopes(data, numPsQId, paramRange, numShots)

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

%Assume that we have nbrRepeats = 1 for now
nbrRepeats = 1;
data = mean(reshape(data,nbrRepeats,[]),1);

%Step by extra 1 to account for ground cal at start of each set
groundCal = mean(data(1:numPsQId+1:end-1));
excitedCal = data(end);

scaledData = (data-groundCal)/(excitedCal-groundCal);
measNoise = var(scaledData(1:numPsQId+1:end-1));
% central limit theorem approximation for the shot noise of an X-Y plane result
shotNoise = 1/numShots;
% actual variance should be measurement noise plus shot noise
varEstimate = sqrt(measNoise^2 + shotNoise^2);

if ~isfield(figHandles, 'DRAG') || ~ishandle(figHandles.('DRAG'))
    figHandles.('DRAG') = figure('Name', 'DRAG');
else
    figure(figHandles.('DRAG')); clf;
end

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
    tmpLine = plot(h, (ct-1)*(numPsQId+1)+2:ct*(numPsQId+1), fitYs, 'r', 'LineWidth', 2);

    %Sort out whether the fit was any good and use the Rsquared to filter
    sse = sum((fitYs-tmpData).^2);
    Rsquared = (sse/varEstimate)/(numPsQId-1);
    if Rsquared < 2 %arbitrary heuristic that seems to match a good fit by eye
        slopes(ct) = fitResult(1);
    else
        slopes(ct) = nan;
        set(tmpLine, 'LineStyle', '--');
    end
end

%Remove the bad fits 
goodFits = ~isnan(slopes);

fitResult = polyfit(paramRange(goodFits), slopes(goodFits),1);

bestParam = -fitResult(2)/fitResult(1);

end