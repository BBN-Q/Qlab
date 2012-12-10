function [decays, err_bars] = analyzeRBTdecays(data, seqsPerFile, nbrFiles, nbrExpts, seqLengthsPerExpt, nbrTwirls, exhaustiveFlags, nbrSoftAvgs, ptraceRepeats, nbrCals, calRepeats)
% analyzeRBTdecays(data,            seqsPerFile,       nbrFiles, 
%                  nbrExpts,        seqLengthsPerExpt, nbrTwirls, 
%                  exhaustiveFlags, nbrSoftAvgs,       ptraceRepeats, 
%                  nbrCals,         calRepeats)
%
%
% r=analyzeRBTdecays(data.abs_Data, 144*3, 5, 9, [1,2,3,0], [12^2, 12^2, 12^3, 12^2], [true, true, true, true], 10, 2, 4, 2);

% rearrange the idices so that they correspond to
% sequence ct, overlap ct, file ct, trace rep ct, soft avg rep ct
reshaped_data = reshape(data',seqsPerFile+nbrCals*calRepeats,nbrSoftAvgs,ptraceRepeats,nbrFiles,nbrExpts);

% now we need to extract the calibration for the data
% we average over the soft average samples, 
cal_data = tensor_mean(reshaped_data(seqsPerFile+1:end,:,:,:,:),2);

% then average over the cal repeats
cal_data = tensor_mean(reshape(cal_data,calRepeats,nbrCals,ptraceRepeats,nbrFiles,nbrExpts),1);

% we want to calibrate qubit data, so we set the upper and lower rails 
cal_data = tensor_mean(tensor_sum(reshape(cal_data,nbrCals/2,2,ptraceRepeats,nbrFiles,nbrExpts),1),2);

% the result is one expectation for ground, one expectation value for
% excited, which we then use to set the scale and shift for the rest of the
% data (each experiment in each file must be rescaled independently)
cal_scale = reshape(cal_data(1,:,:) - cal_data(2,:,:),1,nbrExpts*nbrFiles);
cal_shift = reshape((cal_data(2,:,:) + cal_data(1,:,:))/2,1,nbrExpts*nbrFiles);

% now we can rescale the unaveraged (but traced out) data (useful for bootstraping)
scaled_data = reshape(tensor_sum(reshaped_data(1:seqsPerFile,:,:,:,:),3),seqsPerFile*nbrSoftAvgs,nbrExpts*nbrFiles);
scaled_data = 2*(scaled_data - repmat(cal_shift,[nbrSoftAvgs*seqsPerFile 1]))./repmat(cal_scale,[nbrSoftAvgs*seqsPerFile 1]);
scaled_data = reshape(scaled_data,seqsPerFile,nbrSoftAvgs*nbrExpts*nbrFiles);

% we can now line up all experiments, and have each overlap experiment in a
% different row
scaled_data = permute(reshape(scaled_data,seqsPerFile,nbrSoftAvgs,nbrExpts,nbrFiles),[2,1,3,4]);
scaled_data = reshape(scaled_data,nbrSoftAvgs,seqsPerFile*nbrExpts*nbrFiles);

decays = avg_and_twirl(scaled_data, seqLengthsPerExpt, seqsPerFile, nbrExpts, nbrFiles, nbrTwirls, exhaustiveFlags);

% now we bootstrap to get errorbounds (upper and lower)
stat = @(resampled_data) avg_and_twirl(resampled_data, seqLengthsPerExpt, seqsPerFile, nbrExpts, nbrFiles, nbrTwirls, exhaustiveFlags);
err_bars = bootci(500, stat, scaled_data);
end

function v = vec(M)
  v = reshape(M,prod(size(M)),1);
end

function decays = avg_and_twirl( data, seqLengths, seqsPerFile, nbrExpts, nbrFiles, nbrTwirls, exhaustive )
    % first we average over the random samples & reshape
    avg_data = reshape(tensor_mean(data,1),seqsPerFile*nbrFiles,nbrExpts);
    % and then we bootstrap over the different sequences in the twirl (if not exhaustive), and
    % average over the resulting sequence, 
    bounds = cumsum([0 nbrTwirls]);
%     decays = zeros(length(seqLengths)+2,nbrExpts);
    decays = zeros(length(seqLengths),nbrExpts);
    for ii=1:length(bounds)-1,
        if not(exhaustive(ii)),
            boot_indices = randi([(bounds(ii)+1) bounds(ii+1)],1,bounds(ii+1)-bounds(ii));
            decays(ii,1:nbrExpts) = tensor_mean(avg_data(boot_indices,:),1);
        else
            decays(ii,1:nbrExpts) = tensor_mean(avg_data(bounds(ii)+1:bounds(ii+1),:),1);
        end
    end
%     for jj=1:nbrExpts,
%         % so now we can fit the exponential, by using the last point as the origin
%         [alpha,c] = expfit(1,seqLengths(1),seqLengths(2)-seqLengths(1),...
%             abs(decays(1:length(seqLengths)-1,jj)-decays(length(seqLengths),jj)));
%         decays(length(seqLengths)+1:length(seqLengths)+2,jj)=real([sign(decays(1,jj)-decays(length(seqLengths),jj))*exp(alpha),c]');
%     end    
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
