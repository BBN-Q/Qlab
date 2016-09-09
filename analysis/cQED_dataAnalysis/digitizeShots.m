function [codemat, resultvec, thrvec] = digitizeShots(data,LPNq,ndataq,doDig,signvec)
%function called by LPN
%indmeas = sorted indeces of ancilla and data qubits
%segvec_1 = sorted indeces corresponding to calibration for one qubit in
%|1> and the rest in |0>

ancilla_err = 0.1; %defines the tolerable false counts for postselection on Q3 = |1>. Optional use (set to 0 to disable)
ndata = 10; %number of adjacent shots between calibration points
ncal = 2^(ndataq+1); %number of calibration points every ndata shots

if ndataq==2
indmeas=[1,3,2]; %A, Q1, Q5
%indmeas=[2,3,1]; %A, Q1, Q5
segvec_1=ndata+[3,5,2];
%segvec_1=ndata+[3,9,5];

else %ndataq=3
indmeas=[2,4,1,3]; %A, Q1, Q2, Q5
segvec_1=ndata+[5,17,9,3];
end

nbins=500;
totshots = size(data.data{1},1)*size(data.data{1},2);
repeatNum = totshots/(ndata+ncal);
nshots = totshots-ncal*repeatNum;
bins = zeros(ndataq+1,nbins);
PDFvec = zeros(nbins,ndata+ncal,ndataq+1);
avgdata=zeros(ndata+ncal,ndataq+1);
thrvec = zeros(1,ndataq+1);
datamat=zeros(totshots,ndataq+1);
sorteddata=zeros(nshots/ndata,ndata+ncal,ndataq+1);

for kk=1:ndataq+1
    if(size(data.data{1},2)==1) 
        tempdata = real(data.data{indmeas(kk)}(:,1))';
        datamat(:,kk)=tempdata;
    else
    for mm=1:size(data.data{1},1)
        tempdata = real(data.data{indmeas(kk)}(mm,:))';
        %subtract average between calibration points
        offset = mean(tempdata(segvec_1:ndata+ncal:end));
        tempdata = tempdata - offset;
        datamat(1+(mm-1)*size(data.data{1},2):mm*size(data.data{1},2),kk)=tempdata; %reorder data
    end
    end
    [bins(kk,:), PDFvec(:,:,kk), ~,avgdata(:,kk),thrvec(kk),sorteddata(:,:,kk)] = initByMsmt(datamat(:,kk),ndata+ncal,1,[ndata+1;segvec_1(kk)],[0],1,0,0);
end

if ancilla_err>0 && LPNq==1
    thr_mA = bins(1,find(cumsum(PDFvec(:,ndata+1,1))>ancilla_err,1));  %choose this option for stricter postselection
else
    thr_mA = thrvec(1);
end

codemat = nan(nshots,ndataq);
km=1;

if LPNq==1
    %quantum LPN
    resultvec = zeros(nshots,1);
    for k=1:nshots
        if (signvec(1)== 1 && datamat(km,1) < thr_mA) || (signvec(1)== -1 && datamat(km,1) > thr_mA) %leave unassigned (NaN) otherwise
            resultvec(k) = 1;
            for q=1:ndataq
                if doDig==1
                    codemat(k,q) = -0.5*(signvec(q+1)-1)*(datamat(km,q+1)>=thrvec(q+1)) + 0.5*(signvec(q+1)+1)*(datamat(km,q+1)<thrvec(q+1));
                else
                    codemat(k,q) = datamat(km,q+1);
                end
            end
        end
        if mod(k,ndata)==0
            km=km+ncal;
        end
        km=km+1;
    end

else
    %classical LPN
    resultvec = zeros(nshots,1);
    for k=1:nshots
        for q=1:ndataq
            %if doDig==1
                codemat(k,q)= -0.5*(signvec(q+1)-1)*(datamat(km,q+1)>=thrvec(q+1)) + 0.5*(signvec(q+1)+1)*(datamat(km,q+1)<thrvec(q+1));
            %else
            %    codemat(k,q)= datamat(km,q+1);
            %end
        end
        %if doDig==1
            resultvec(k) = -0.5*(signvec(1)-1)*(datamat(km,1)>=thr_mA) + 0.5*(signvec(1)+1)*(datamat(km,1)<thr_mA);
        %else
        %    resultvec(k) = datamat(km,1);
        %end
        if mod(k,ndata)==0
            km=km+ncal;
        end
        km=km+1;
    end
end
end

    
    

            

    
