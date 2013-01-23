function scaledData = analyzeRBT(data)

calRepeats = 2;
%Number of overlaps
nbrExpts = 10;

%Number of twirl sequences at each length
nbrTwirls = [12^2, 12^2, 12^3, 12^2, 12^2];
twirlOffsets = 1 + [0, cumsum(nbrTwirls)];

%Length of sequences (cell array (length nbrExpts) of arrays) 
seqLengths = repmat({[1 2 3 4 10]}, 1, nbrExpts);

%Cell array or array of boolean whether we are exhaustively twirling or randomly sampling
exhaustiveTwirl = repmat({[true, true, true, false, true]}, 1, nbrExpts);

%Number of bootstrap replicas
numReplicas = 500;

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
    % pull out rows corresponding to a given overlap
%     if expct == 1, nbrRows = 2; else nbrRows = 8; end
    nbrRows = 8;
    tmpData = scaledData(rowct:rowct+nbrRows-1,:).';
    tmpData = tmpData(:);
    
    % calculate means and std deviations of each sequence length
    avgFidelities{expct} = zeros(1, length(nbrTwirls));
    variances{expct} = zeros(1, length(nbrTwirls));
    errors{expct} = zeros(1, length(nbrTwirls));
    for twirlct = 1:length(nbrTwirls)
        twirlData = tmpData(twirlOffsets(twirlct):twirlOffsets(twirlct+1)-1);
        avgFidelities{expct}(twirlct) = 0.5 * (1 + mean(twirlData));
        errors{expct}(twirlct) = 0.5 * std(twirlData)/sqrt(nbrTwirls(twirlct));

        %If we have exhaustively twirled we have to be careful in
        %boostrapping to sample evenly from the twils to ensure there no
        %sequence variance contribution
        if exhaustiveTwirl{expct}(twirlct)
            if seqLengths{expct}(twirlct) == 1 || seqLengths{expct}(twirlct) == 10,
                %For length 1 twirls there are 12 possiblilites which we
                %repeat 12x.  To estimate the variance of the mean we
                %resample each set of 12 twirls, numReplicate times and
                %estimate the variance of the mean.
                %We go through all possible sequences 12x so each column of
                %twirlData looks like 1,2,3,...12,1,2,3...,12
                %After reshaping constant twirls along each row
                t = reshape(twirlData,12,12);
                variances{expct}(twirlct) = var(arrayfun(@(n) mean(arrayfun(@(c) mean(resample(t(c,:))),1:12)),zeros(numReplicas,1)));
            elseif seqLengths{expct}(twirlct) == 2,
                %For length 2 there are 12^2 possibilites but we only have
                %1 instance of each so boostrapping is impossible.
                %However, we can assume the noise variance is the same as
                %the length 1 case 
                variances{expct}(twirlct) = variances{expct}(seqLengths{expct}==1);
            elseif seqLengths{expct}(twirlct) == 3,
                %For length 3 there are 12^3 possibilities. Assume the
                %variances is like the length 1 case over 12.
                variances{expct}(twirlct) = variances{expct}(seqLengths{expct}==1) / sqrt(12);
            end
        else
            %Otherwise we apply standard boostrapping. 
            variances{expct}(twirlct) = var(arrayfun(@(x) mean(resample(twirlData)), zeros(numReplicas,1)));
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

% betas = sillyFit2(seqLengths, avgFidelities, variances);
betas = forcedFit(seqLengths, avgFidelities, variances);

fitFidelities = cellfun(@(x) x(1), betas);
[choiSDP,pauliMap,pauliMapRaw] = overlaps_tomo(fitFidelities);

hadPauliMap = [1 0 0 0; 0 0 0 1; 0 0 -1 0; 0 1 0 0];
trace(hadPauliMap*pauliMap)/4
trace(hadPauliMap*pauliMapRaw)/4

end

function vr = resample( v )
  rindices = randi([1 length(v)],1,length(v));
  vr = v(rindices);
end

function betas = forcedFit(seqLengths, avgFidelities, variances)

    betas = cell(1, length(seqLengths));
    % pGuess = [0, 1-offset, offset];
    % pUpper = [1, 1-offset + offsetStd, offset+offsetStd];
    % pLower = [-1/3, 1-offset - offsetStd, offset-offsetStd];
    for exptct = 1:length(seqLengths)
        % seed guess via polynomial solution from first 3 data points 
        % and offset (5th point)
        x = avgFidelities{exptct};
        v = variances{exptct};
        stds = sqrt(v);

        offset = x(5);
        p = (x(2) - offset)/(x(1) - offset);
        % p = real(exp(expfit(1,1,1,x-x(5))));
        % scale = (x(1) - offset)/p;
        pGuess = [p, .5, offset];
        pUpper = [1,    .5+.02, offset+2*stds(5)];
        pLower = [-1/3, .5-.02, offset-2*stds(5)];

        fitf = @(p,n) (p(2)*(p(1).^n) + p(3));
        fitDiffFunc = @(p) (1./sqrt(variances{exptct})).*(fitf(p, seqLengths{exptct}) - avgFidelities{exptct});
        betas{exptct} = lsqnonlin(fitDiffFunc, pGuess, pLower, pUpper);
%         badness = 1E8;
%         for jj=1:100,
%             fitf = @(p,n) (p(2)*(p(1).^n) + p(3));
%             fitDiffFunc = @(p) (1./sqrt(variances{exptct})).*(fitf(p, seqLengths{exptct}) - avgFidelities{exptct});
%             pGuess = [p, .5, offset] + randn(1,3).*[stds(5),.02,stds(5)];
%             tmpBeta = lsqnonlin(fitDiffFunc, pGuess, pLower, pUpper);
%             newBadness = norm(fitDiffFunc(tmpBeta))^2;
%             if newBadness < badness,
%                 betas{exptct} = tmpBeta;
%                 badness = newBadness;
%             end
%         end
    end
    pGuess;
end

function betas = sillyFit2(seqLengths, avgFidelities, variances)

    % fake augmentation of seqLengths
%     seqLengths=[seqLengths 10:5:20];

    betas = cell(1, length(seqLengths));
    % pGuess = [0, 1-offset, offset];
    % pUpper = [1, 1-offset + offsetStd, offset+offsetStd];
    % pLower = [-1/3, 1-offset - offsetStd, offset-offsetStd];
    for exptct = 1:length(seqLengths)
        % fake data
%         avgFidelities{exptct} = [avgFidelities{exptct} avgFidelities{exptct}(5)*ones(1,3)];
%         variances{exptct} = [variances{exptct} variances{exptct}(5)*ones(1,3)];

        % seed guess via polynomial solution from first 3 data points
        x = avgFidelities{exptct};
        v = variances{exptct};
        stds = 3*sqrt(v);
        posx = abs(x-x(5))+x(5);
        xU = posx + stds;
        xL = posx - stds;
        % makes guesses based on assumption of infinite samples
        % pick lower and upper bounds 
        p = (x(2) - x(5))/(x(1) - x(5));
        pB = [(xU(2) - xL(5))/(xL(1) - xU(5)), (xL(2) - xU(5))/(xU(1) - xL(5))];
        pB = pB.*(pB>0);
        pB(pB==0) = .2;
        scale = (x(1) - x(5))/p;
        scaleB = [ (xU(1) - xL(5))/min(pB), (xL(1) - xU(5))/max(pB) ]; 
        % we pick a fixed initial guess that depends only on the sign of
        % the estimated p
        pGuess = [p, .5, x(5)];
        if p < 0,
            pB = -pB;
        end
        pUpper = [max(min(max(pB),1),-1/3), min(max(scaleB),1), xU(5)];
        pLower = [min(max(min(pB),-1/3),1), max(min(scaleB),.2), xL(5)];
        if pUpper(1) == -1/3,
            pUpper(1) = -1/3+stds(1);
        elseif pLower == 1,
            pLower = 1-stds(1);
        end
        
        % pInit = p;
        % fitf = @(p,n) (p(2)*((sign(pInit)*1/3).^n) + offset);
        fitf = @(p,n) (p(2)*(p(1).^n) + p(3));
        fitDiffFunc = @(p) (1./sqrt(variances{exptct})).*(fitf(p, seqLengths{exptct}) - avgFidelities{exptct});
        betas{exptct} = lsqnonlin(fitDiffFunc, pGuess, pLower, pUpper);
        badness = norm(fitDiffFunc(betas{exptct}))^2;
        for ii=1:100,
          pPert = rand(1,3).*(pUpper-pLower);
          tempBeta = lsqnonlin(fitDiffFunc, pLower + pPert, pLower, pUpper);
          if norm(fitDiffFunc(tempBeta))^2 < badness,
              betas{exptct} = tempBeta;
              badness = norm(fitDiffFunc(tempBeta))^2
          end
        end
        pGuess;
    end
% forced
%  -0.3333    0.2813   -0.3244    0.2592    0.3415    0.3115    0.3479    0.2788   -0.3115   -0.3167
% silly
% 1 stddev
%  -0.3333    0.2233   -0.1752    0.2585    0.2607    0.3335    0.2997    0.2286   -0.3333   -0.2929
% 2 stddev
%  -0.3333    0.2245   -0.2483    0.2588    0.2714    0.3317    0.3003    0.2634   -0.3333   -0.2901
% 3 stddev
%  -0.3333   -0.0137   -0.3260   -0.0150    0.2713    0.3334    0.3020    0.2727   -0.3333   -0.2902
%  -0.3333    0.2249   -0.2000    0.2586    0.2712    0.3333    0.2979    0.2623   -0.3333   -0.2904
end