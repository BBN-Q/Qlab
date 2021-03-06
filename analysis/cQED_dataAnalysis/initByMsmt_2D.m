function [bins, PDFvec,data_con,var_con,opt_thr,datamat, fidvec_un, err0, err1] = initByMsmt_2D(data,Anum,numSegments,numMeas_A,indMeas,selectMeas,selectSign,threshold,docond,numCal)
%data = data qubits
%data = single ancilla qubit. Data to be postselected on
%Anum = index of ancilla measurement
%numSegments = number of distinct segments in the sequence
%numMeas_A = number of ancilla measurements per segments (including those to be conditioned on)
%indMeas = list of indeces of the msmt's to compare for fidelity
%selectMeas = indeces of msms't to postselect on. All the msm'ts in a
     %segment will be postselected on this one
%selectSign = select the sign for postselection. 1 = keep greater than; 
     %-1 = keep smaller than
%threshold
%docond. If 1, do postselection
%numCal = number of calibration sequences. Currently, it assumes that they only have 1
%measurement per qubit.

numMeas_D=numMeas_A; 
%the number of data measurements can be different from numMeas_A. For
%instance, there may be multiple conditioning rounds before data
%tomography. However, there is currently the constraint that all channels,
%even if in different cards, acquire the same number of shots. 

ind0=indMeas(1,:);
ind1=indMeas(2,:);

data_A = data.data{Anum};
data_D = cell(1,size(data.data,2)-1);
datamat = cell(1,size(data.data,2)-1);
var_con = cell(1,size(data.data,2)-1);
data_con = cell(1,size(data.data,2)-1);
ind=1;
for kk = 1:size(data.data,2)-1
    if ind == Anum
        ind = ind+1;
    end
        data_D{kk} = data.data{ind};
        ind=ind+1;
end

numShots_A = floor(length(data_A)/(numMeas_A*(numSegments-numCal)+numCal));
for kk = 1:size(data_D,2)
    datamat{kk} = splitdata(real(data_D{kk}),numShots_A,numMeas_D*(numSegments-numCal)+numCal);
end
data_A=real(data_A);
datamat_A = splitdata(data_A,numShots_A,numMeas_A*(numSegments-numCal)+numCal);
bins = linspace(min(min(datamat_A)), max(max(datamat_A)),500);

PDFvec = zeros(length(bins),numMeas_A*(numSegments-numCal)+numCal);
%PDFvec_con = zeros(length(bins),numMeas*numSegments);

for kk=1:numMeas_A*(numSegments-numCal)+numCal
    PDFvec(:,kk) = ksdensity(datamat_A(:,kk), bins);
    %PDFvec(:,kk) = hist(datamat(:,kk), bins);

end

opt_thr = zeros(length(ind0),1);
fidvec_un = zeros(length(ind0),1);
%fidvec_con = zeros(length(ind0),1);
err0 = zeros(length(ind0),1);
err1 = zeros(length(ind0),1);
datatemp = zeros(numSegments, numMeas_D)%-length(selectMeas));
vartemp = zeros(numSegments, numMeas_D)%-length(selectMeas));


for kk=1:size(PDFvec,2)
    PDFvec(:,kk)=PDFvec(:,kk)/sum(PDFvec(:,kk));
    PDFvec(:,kk)=PDFvec(:,kk)/sum(PDFvec(:,kk));
end

for kk=1:length(ind0)
    fidvec_un(kk) = 1-0.5*(1-0.5*sum(abs(PDFvec(:,ind0(kk))-PDFvec(:,ind1(kk)))));
    [~,indmax] = max(abs(cumsum(PDFvec(:,ind0(kk)))-cumsum(PDFvec(:,ind1(kk)))));
    fprintf('Optimum unconditioned fid. for segm. %d and %d = %.3f\n', ind0(kk), ind1(kk), fidvec_un(kk));  
    tempvec0 = cumsum(abs(PDFvec(:,ind0(kk))));
    %[~, indc] = min(abs(bins+0.3789));
    err0(kk) = tempvec0(indmax); %(indmax); %indc to keep it fixed to the 0000 vs 0001 value
    %fprintf('Error for |0> for segm. %d and %d = %.3f\n', ind0(kk), ind1(kk), tempvec0(indmax));
    tempvec1 = 1-cumsum(abs(PDFvec(:,ind1(kk))));
    err1(kk) = tempvec1(indmax); %(indmax);
    %fprintf('Error for |1> for segm. %d and %d = %.3f\n', ind0(kk), ind1(kk), tempvec1(indmax)); 
    opt_thr(kk) = bins(indmax);
    fprintf('Optimum threshold for segments %d and %d = %.4f\n', ind0(kk), ind1(kk), opt_thr(kk));  
end

if(docond)
    for nn = 1:size(data_D,2)
        dataslice = datamat{nn};
        for mm=1:numSegments-numCal
            for kk=1:length(selectMeas)
                ind = selectMeas(kk);
                
                for jj=1:numShots_A*numMeas_A/numMeas_D
                    if selectSign(kk) == 1 && datamat_A(jj,numMeas_A*(mm-1)+ind) < threshold
                        dataslice(jj,numMeas_A*(mm-1)+1:numMeas_A*(mm-1)+numMeas_A)=NaN;
                    elseif selectSign(kk) == -1 && datamat_A(jj,numMeas_A*(mm-1)+ind) > threshold
                        dataslice(jj,numMeas_A*(mm-1)+1:numMeas_A*(mm-1)+numMeas_A)=NaN;
                    end
                end
                
            end
        end
     datamat{nn} = dataslice;
     end
   
    fprintf('Fraction kept = %.2f\n',  sum(sum(~isnan(dataslice(:,1:end-numCal))))/(size(dataslice,1)*(size(dataslice,2)-numCal)));
end

for nn=1:size(data_D,2)
    dataslice = datamat{nn};
for jj=1:numSegments
    thismeas=1;
    for kk=1:numMeas_D
        %PDFvec_con(:,(jj-1)*numMeas+kk) =
        %ksdensity(datamat(:,numMeas*(jj-1)+kk), bins); ignore for now.
        %This is the conditioned distribution of data qubit results
        %if(size(find(kk==selectMeas),1)==0) %this condition is necessary
        %not to condition a measurement on itself. This does not occur with
        %feed-forward schemes (i.e., data qubits conditioned on ancilla)
        if jj<numSegments-numCal+1
            datatemp(jj, thismeas) = nanmean(dataslice(:,numMeas_D*(jj-1)+kk)); 
            vartemp(jj, thismeas) = nanvar(dataslice(:, numMeas_D*(jj-1)+kk));
        else
            datatemp(jj, thismeas) = nanmean(dataslice(:,numMeas_D*(numSegments-numCal) + (jj-(numSegments-numCal))));
            vartemp(jj, thismeas) = nanvar(dataslice(:,numMeas_D*(numSegments-numCal) + (jj-(numSegments-numCal)))); %same cal. points for all data measurements
        end
        thismeas=thismeas+1;
    end
end
    data_con{nn} = datatemp;
    var_con{nn} = vartemp;
end


%normalize
% for kk=1:size(PDFvec_con,2)
%     PDFvec_con(:,kk)=PDFvec_con(:,kk)/sum(PDFvec_con(:,kk));
%     PDFvec_con(:,kk)=PDFvec_con(:,kk)/sum(PDFvec_con(:,kk));
% end
% 
% 
% for kk=1:length(ind0)
%     fidvec_con(kk) = 1-0.5*(1-0.5*sum(abs(PDFvec_con(:,ind0(kk))-PDFvec_con(:,ind1(kk)))));
%     %fprintf('Optimum conditioned fid. for segm. %d and %d = %.3f\n', ind0(kk), ind1(kk), fidvec_con(kk));  
% end

end



