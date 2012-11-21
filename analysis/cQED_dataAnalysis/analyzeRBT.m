function scaledData = analyzeRBT(data)

calRepeats = 2;
%Number of overlaps
nbrExpts = 9;

%Number of twirl sequence realizations (array of length nbrExpts)
nbrRepeats = [36, repmat(24^2, 1, nbrExpts-1)];
% nbrRepeats = 24^2*ones(1, nbrExpts);

%Length of sequences (cell array (length nbrExpts) of arrays) 
seqLengths = [{[2, 5, 8, 13, 16, 20, 25, 30, 32, 40, 49, 55, 64, 101, 126, 151]}, repmat({1:6}, 1, nbrExpts-1)];
% seqLengths = repmat({1:6}, 1, nbrExpts);

%Cell array or array of boolean whether we are exhaustively twirling or randomly sampling
exhaustiveTwirl = [{false([1, 16])}, repmat({[true, true, false, false, false, false]}, 1, nbrExpts-1)];
% exhaustiveTwirl = repmat({[true, true, false, false, false, false]}, 1, nbrExpts);

%Number of bootstrap replicates
numReplicates = 200;

scaledData = zeros(size(data,1), size(data,2)-2*calRepeats);
avgFidelities = cell(nbrExpts, 1);
variances  = cell(nbrExpts, 1);
errors = cell(nbrExpts, 1);
fitFidelities = zeros(nbrExpts, 1);

for rowct = 1:size(data,1)
    % calScale each row
    zeroCal = mean(data(rowct, end-2*calRepeats+1:end-calRepeats));
    piCal = mean(data(rowct, end-calRepeats+1:end));
    scaleFactor = (zeroCal - piCal)/2;
    
    scaledData(rowct, :) = (data(rowct, 1:end-2*calRepeats) - piCal)./scaleFactor - 1;
end

%Restack experiments and pull out avgerage fidelities
rowct = 1;
for expct = 1:nbrExpts
    if expct == 1, nbrRows = 2; else nbrRows = 12; end
%     nbrRows = 12;
    tmpData = scaledData(rowct:rowct+nbrRows-1,:).';
    tmpData = tmpData(:);
    
    % calculate means and std deviations of each sequence length
    avgFidelities{expct} = 0.5 * (1 + mean(reshape(tmpData, nbrRepeats(expct), length(seqLengths{expct}) )));
    variances{expct} = zeros(size(avgFidelities{expct}));
    errors{expct} = 0.5 * std(reshape(tmpData, nbrRepeats(expct), length(seqLengths{expct})))/sqrt(nbrRepeats(expct));
    
    %Reshape tmpData row vector into matrix numRepeats x numSeqLengths
    t = reshape(tmpData, nbrRepeats(expct), length(seqLengths{expct}) );
    
    for lengthct = 1:size(t,2)
        %If we have exhaustively twirled we have to be careful in
        %boostrapping to sample evenly from the twils to ensure there no
        %sequence variance contribution
        if exhaustiveTwirl{expct}(lengthct)
            if seqLengths{expct}(lengthct) == 1,
                %For length 1 twirls there are 24 possiblilites which we
                %repeat 24x.  To estimate the variance of the mean we
                %resample each set of 24 repeats, numReplicate times and
                %estimate the variance of the mean.
                %We go through all possible sequences 24x so each column of
                %t looks like 1,2,3,...24,1,2,3...,24
                %After reshaping constant twirls along each row
                t2 = reshape(t(:,lengthct),24,24);
                variances{expct}(lengthct) = var(arrayfun(@(n) mean(arrayfun(@(c) mean(resample(t2(c,:))),1:24)),zeros(numReplicates,1)));
            elseif seqLengths{expct}(lengthct) == 2,
                %For length 2 there are 24^2 possibilites but we only have
                %1 instance of each so boostrapping is impossible.
                %However, we can assume the noise variance is the same as
                %the length 1 case 
                variances{expct}(lengthct) = variances{expct}(seqLengths{expct}==1);
            end
        else
            %Otherwise we apply standard boostrapping. 
            variances{expct}(lengthct) = var(arrayfun(@(x) mean(resample(t(:,lengthct))), zeros(numReplicates,1)));
        end
    end
    
    rowct = rowct+nbrRows;
end    
    

%Now fit decays

%First fit the identity sequence to get bounds for offsets
% fitf = @(p,n) (p(2)*p(1).^n + p(3));
% weighted_fitf = @(p,n) (1./sqrt(variances{1})).*fitf(p,n);
% [beta, r, j] = nlinfit(seqLengths{1}, (1./sqrt(variances{1})).*avgFidelities{1}, weighted_fitf, [0.99, 0.5, 0.5]);
% fitFidelities(1) = beta(1);
% % get confidence intervals
% ci = nlparci(beta,r,j);
% 
% % beta = [0.99, 0.5, 0.5];
% % ci = [0.98, 1; 0.48, 0.52; 0.48, 0.52];
% 
% pGuess = [0, beta(2), beta(3)];
% pLower = [-1, ci(2,1), ci(3,1)]; 
% pUpper = [1, ci(2,2), ci(3,2)];
% 
% %Now fit the rest
% for rowct = 2:nbrExpts
%     fitDiffFunc = @(p) (1./sqrt(variances{rowct})).*(fitf(p, seqLengths{rowct}) - avgFidelities{rowct});
%     fitResult = lsqnonlin(fitDiffFunc, pGuess, pLower, pUpper);
%     fitFidelities(rowct) = fitResult(1);
% end

betas = sillyFit2(seqLengths, avgFidelities, variances);
fitFidelities = cellfun(@(x) x(1), betas);
choiSDP = overlaps_tomo(fitFidelities);

end

function vr = resample( v )
  rindices = randi([1 length(v)],1,length(v));
  vr = v(rindices);
end