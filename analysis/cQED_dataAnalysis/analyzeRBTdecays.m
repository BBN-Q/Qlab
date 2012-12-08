function decays = analyzeRBTdecays(data, seqsPerFile, nbrFiles, nbrExpts, seqLengthsPerExpt, nbrTwirls, exhaustiveFlags, nbrSoftAvgs, ptraceRepeats, nbrCals, calRepeats)
% analyzeRBTdecays(data,            seqsPerFile,       nbrFiles, 
%                  nbrExpts,        seqLengthsPerExpt, nbrTwirls, 
%                  exhaustiveFlags, nbrSoftAvgs,       ptraceRepeats, 
%                  nbrCals,         calRepeats)
%
%
% r=analyzeRBTdecays(data.abs_Data, 144*3, 5, 9, [1,2,3,0], [12^2, 12^2, 12^3, 12^2], [true, true, true, true], 10, 2, 4, 2);

% overlap, file, trace, sequence, soft,

% rearrange the idices so that they correspond to
% sequence ct, overlap ct, file ct, trace rep ct, soft avg rep ct
% reshaped_data = reshape(data',seqsPerFile+nbrCals*calRepeats,nbrSoftAvgs,nbrExpts,nbrFiles,ptraceRepeats);

reshaped_data = reshape(data',seqsPerFile+nbrCals*calRepeats,nbrSoftAvgs,ptraceRepeats,nbrExpts,nbrFiles);
% TODO: nbrFiles should come before nbrExpts

% now we need to extract the calibration for the data
% we average over the soft average samples, 
cal_data = tensor_mean(reshaped_data(seqsPerFile+1:end,:,:,:,:),2);

% then average over the cal repeats
%cal_data = tensor_mean(reshape(cal_data,calRepeats,nbrCals,nbrExpts,nbrFiles,ptraceRepeats),1);
cal_data = tensor_mean(reshape(cal_data,calRepeats,nbrCals,ptraceRepeats,nbrExpts,nbrFiles),1);

% we want to calibrate qubit data, so we set the upper and lower rails 
% cal_data = tensor_mean(tensor_sum(reshape(cal_data,nbrCals/2,2,nbrExpts,nbrFiles,ptraceRepeats),1),4);
cal_data = tensor_mean(tensor_sum(reshape(cal_data,nbrCals/2,2,ptraceRepeats,nbrExpts,nbrFiles),1),2);

% the result is one expectation for ground, one expectation value for
% excited, which we then use to set the scale and shift for the rest of the
% data (each experiment in each file must be rescaled independently)
cal_scale = reshape(cal_data(2,:,:) - cal_data(1,:,:),1,nbrExpts*nbrFiles);
cal_shift = reshape((cal_data(2,:,:) + cal_data(1,:,:))/2,1,nbrExpts*nbrFiles);

% now we can rescale the unaveraged (but traced out) data (useful for bootstraping)
% scaled_data = reshape(tensor_sum(reshaped_data(1:seqsPerFile,:,:,:,:),5),seqsPerFile*nbrSoftAvgs,nbrExpts*nbrFiles);
% scaled_data = (scaled_data - repmat(cal_shift,[nbrSoftAvgs*seqsPerFile 1]))./repmat(cal_scale,[nbrSoftAvgs*seqsPerFile 1]);
% scaled_data = reshape(scaled_data,seqsPerFile,nbrSoftAvgs*nbrExpts*nbrFiles);

scaled_data = reshape(tensor_sum(reshaped_data(1:seqsPerFile,:,:,:,:),3),seqsPerFile*nbrSoftAvgs,nbrExpts*nbrFiles);
scaled_data = (scaled_data - repmat(cal_shift,[nbrSoftAvgs*seqsPerFile 1]))./repmat(cal_scale,[nbrSoftAvgs*seqsPerFile 1]);
scaled_data = reshape(scaled_data,seqsPerFile,nbrSoftAvgs*nbrExpts*nbrFiles);

% stopped at this point, and data looks mangled. Indices must be incorrect.

% now we can rescale the averaged, reshaped data
reshaped_data = reshape(tensor_mean(tensor_sum(reshaped_data(1:seqsPerFile,:,:,:,:),5),2),seqsPerFile,nbrExpts*nbrFiles);
%scaled_avg_data = (reshaped_data - repmat(cal_shift,[seqsPerFile 1]))./repmat(cal_scale,[seqsPerFile 1]);
scaled_avg_data = reshaped_data;

% we can now line up all experiments, and have each overlap experiment in a
% different row
scaled_avg_data = permute(reshape(scaled_avg_data,seqsPerFile,nbrExpts,nbrFiles),[1,3,2]);
scaled_avg_data = reshape(scaled_avg_data,seqsPerFile*nbrFiles,nbrExpts);

% now we sum over the twirls
bounds = cumsum([0 nbrTwirls]);
decays = zeros(length(nbrTwirls),nbrExpts);
for ii=1:length(bounds)-1,
    decays(ii,:) = sum(scaled_avg_data(bounds(ii)+1:bounds(ii)+1,:),2);
end
decays = decays;

% now put all files in an overlap together
% reshaped_data = reshape(permute(reshaped_data,[3,2,1,4,5]),);

% analyzeRBTdecays(data.abs_Data, 9, [1,2,3,0], [12^2, 12^2, 12^3, 12^2], [true, true, true, true], 5, 2, 4, 2)
%
% in order to re structre the data, we need to know
%
% number of overlaps
% sequence lengths per overlap
% sequence types per length (not uniform)
% soft average repetition per type
% partial trace exp per repetition
%
% if we want to resample the data, we also need to know
% if the enumeration of sequence types is exhaustive or not.
%
% with this information we should be able to more easily (and flexibly) 
% analyze the data from many differen kinds of experiments
%
% call as
%
% analyzeRBTdecays(data, nbrOverlaps, seqLengths, seqTypeCounts, exhaustiveFlag, nbrSoftAvg, nbrPTraceExp)
%
% and return an array where:
%
% each column is a sequence length
% each row is an overlap
% each entry is the estimate expectation value
%
% and 2 arrays as above but where each entry is the upper error bar bound,
% and the other is the lower error bar bound, estimated by bias corrected
% and accelerate bootstrap.
%
% Another function would fit the data to decays, while yet another would
% estimate uncertainty in the fit parameters.

%Number of twirl sequences at each length
twirlOffsets = 1 + [0, cumsum(nbrTwirls)];

%Length of sequences (cell array (length nbrExpts) of arrays) 
seqLengths = repmat({seqLengthsPerExpt}, 1, nbrExpts);

%Cell array or array of boolean whether we are exhaustively twirling or randomly sampling
exhaustiveTwirl = repmat({exhaustiveFlags}, 1, nbrExpts);

%Number of bootstrap replicas
numReplicas = 500;

scaledData = zeros(size(data,1), size(data,2)-nbrCals*calRepeats);
avgFidelities = cell(nbrExpts, 1);
variances  = cell(nbrExpts, 1);
errors = cell(nbrExpts, 1);
fitFidelities = zeros(nbrExpts, 1);

nbrAvgs = ptraceRepeats * nbrSoftAvgs;
for rowct = 1:nbrAvgs:size(data,1)
    % calScale each row
    zeroCal = mean(vec(data(rowct:rowct+nbrAvgs-1, end-nbrCals*calRepeats+1:end-(nbrCals-1)*calRepeats)));
    piCal   = mean(vec(data(rowct:rowct+nbrAvgs-1, end-(nbrCals-1)*calRepeats+1:end)));
    scaleFactor = (zeroCal - piCal)/2;
    
    scaledData(rowct:rowct+nbrAvgs-1, :) = (data(rowct:rowct+nbrAvgs-1, 1:end-nbrCals*calRepeats) - piCal)./scaleFactor - 1;
end

% new we can reshape the data so that each row corresponds to a soft
% averaged repetition. We can generate bootstrap samples by sampling from
% each column separately.
sampledData=reshape(scaledData',nbrSoftAvgs*ptraceRepeats,nbrExpts*sum(nbrTwirls));

% now we need to average the soft averaging repetitions
% break it down into separate overlaps
avgData = reshape(mean(sampledData),nbrExpts,sum(nbrTwirls));

%decays=sampledData;
end

function v = vec(M)
  v = reshape(M,prod(size(M)),1);
end

function t = tensor_sum( M, v )
    s = size(M);
    ii = 1:length(s);
    vbar = setdiff(ii,v);
    t = sum(reshape(permute(M,[vbar v]),[s(vbar) prod(s(v))]),length(vbar)+1);
end

function t = tensor_mean( M, v )
    s = size(M);
    ii = 1:length(s);
    vbar = setdiff(ii,v);
    t = mean(reshape(permute(M,[vbar v]),[s(vbar) prod(s(v))]),length(vbar)+1);
end
