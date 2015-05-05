function [bins, PDFvec, PDFvec_con,data_con,opt_thr,datamat] = initByMsmt(data,numSegments,numMeas,indMeas,selectMeas,selectSign,threshold,docond)
%numSegments = number of distinct segments in the sequence
%numMeas = number of meauserements per segments
%indMeas = list of indeces of the msmt's to compare for fidelity
%selectMeas = indeces of msms't to postselect on. All the msm'ts in a
     %segment will be postselected on this one
%selectSign = select the sign for postselection. 1 = keep greater than; 
     %-1 = keep smaller than
%threshold
%docond. If 1, do postselection

ind0=indMeas(1,:);
ind1=indMeas(2,:);

numShots = floor(length(data)/(numMeas*numSegments));
data=real(data)';
datamat = splitdata(data,numShots,numMeas*numSegments);
bins = linspace(min(min(datamat)), max(max(datamat)));

PDFvec = zeros(length(bins),numMeas*numSegments);
PDFvec_con = zeros(length(bins),numMeas*numSegments);

for kk=1:numMeas*numSegments
    PDFvec(:,kk) = ksdensity(datamat(:,kk), bins);
end

opt_thr = zeros(length(ind0),1);
fidvec_un = zeros(length(ind0),1);
fidvec_con = zeros(length(ind0),1);
data_con = zeros(numSegments, numMeas-length(selectMeas));


for kk=1:size(PDFvec,2)
    PDFvec(:,kk)=PDFvec(:,kk)/sum(PDFvec(:,kk));
    PDFvec(:,kk)=PDFvec(:,kk)/sum(PDFvec(:,kk));
end

for kk=1:length(ind0)
    fidvec_un(kk) = 1-0.5*(1-0.5*sum(abs(PDFvec(:,ind0(kk))-PDFvec(:,ind1(kk)))));
    [~,indmax] = max(abs(cumsum(PDFvec(:,ind0(kk)))-cumsum(PDFvec(:,ind1(kk)))));
    fprintf('Optimum unconditioned fid. for segm. %d and %d = %.3f\n', ind0(kk), ind1(kk), fidvec_un(kk));  
    opt_thr(kk) = bins(indmax);
    fprintf('Optimum threshold for segments %d and %d = %.4f\n', ind0(kk), ind1(kk), opt_thr(kk));  
end

if(docond)
    for mm=1:numSegments
        for kk=1:length(selectMeas)
            ind = selectMeas(kk);
            for jj=1:numShots
                if selectSign == 1 && datamat(jj,numMeas*(mm-1)+ind) < threshold
                    datamat(jj,numMeas*(mm-1)+1:numMeas*(mm-1)+numMeas)=NaN;
                elseif selectSign == -1 && datamat(jj,numMeas*(mm-1)+ind) > threshold
                    datamat(jj,numMeas*(mm-1)+1:numMeas*(mm-1)+numMeas)=NaN;
                end
            end
        end
    end
   
    fprintf('Fraction kept = %.2f\n',  sum(sum(~isnan(datamat)))/(size(datamat,1)*size(datamat,2)));
end

for jj=1:numSegments
    thismeas=1;
    for kk=1:numMeas
        PDFvec_con(:,(jj-1)*numMeas+kk) = ksdensity(datamat(:,numMeas*(jj-1)+kk), bins);
        if(size(find(kk==selectMeas),1)==0)
            data_con(jj,thismeas) = nanmean(datamat(:,numMeas*(jj-1)+kk));
            thismeas=thismeas+1;
        end
    end
end

%normalize
for kk=1:size(PDFvec_con,2)
    PDFvec_con(:,kk)=PDFvec_con(:,kk)/sum(PDFvec_con(:,kk));
    PDFvec_con(:,kk)=PDFvec_con(:,kk)/sum(PDFvec_con(:,kk));
end


for kk=1:length(ind0)
    fidvec_con(kk) = 1-0.5*(1-0.5*sum(abs(PDFvec_con(:,ind0(kk))-PDFvec_con(:,ind1(kk)))));
    fprintf('Optimum conditioned fid. for segm. %d and %d = %.3f\n', ind0(kk), ind1(kk), fidvec_con(kk));  
end

end



