function [codemat, resultvec, thrvec] = digitizeShots(data,LPNq,ndataq,doDig,signvec)
%function called by LPN
%indmeas = sorted indeces of ancilla and data qubits
%segvec_1 = sorted indeces corresponding to calibration for one qubit in
%|1> and the rest in |0>

if ndataq==2
indmeas=[2,3,1]; %A, Q1, Q2
segvec_1=[103,109,105];
else %ndataq=3
indmeas=[2,4,1,3]; %A, Q1, Q2, Q5
segvec_1=[105,117,109,103];
end

ndata = 100; %number of adjacent shots between calibration points
ncal = 2^(ndataq+1)*2; %number of calibration points every ndata shots

totshots = size(data.data{1},1)*size(data.data{1},2);
repeatNum = totshots/(ndata+ncal);
nshots = totshots-ncal*repeatNum;
ancilla_err = 0.1; %defines the tolerable false counts for postselection on Q3 = |1>. Optional use
bins = zeros(ndataq+1,100);
PDFvec = zeros(100,ndata+ncal,ndataq+1);
avgdata=zeros(ndata+ncal,ndataq+1);
thrvec = zeros(1,ndataq+1);
datamat=zeros(totshots,ndataq+1);

for kk=1:ndataq+1
    tempdata=data.data{indmeas(kk)};
    tempdata = real(reshape(tempdata',totshots,1));
    datamat(:,kk)=tempdata; %reorder data
    [bins(kk,:), PDFvec(:,:,kk), ~,avgdata(:,kk),thrvec(kk)] = initByMsmt(tempdata,ndata+ncal,1,[101;segvec_1(kk)],[0],1,0,0);
end
thr_mA= thrvec(1); %bins_m3(find(cumsum(PDFvec_m3(:,101))>ancilla_err,1));  %choose the second option for stricter postselection

codemat = nan(nshots,ndataq);
km=1;

if LPNq==1
    %quantum LPN
    resultvec = zeros(nshots,1); %unnecessary
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
        if mod(k,100)==0
            km=km+16;
        end
        km=km+1;
    end

else
    %classical LPN
    resultvec = zeros(nshots,1);
    for k=1:nshots
        for q=1:ndataq
            codemat(k,q)= -0.5*(signvec(q+1)-1)*(datamat(km,q+1)>=thrvec(q+1)) + 0.5*(signvec(q+1)+1)*(datamat(km,q+1)<thrvec(q+1));
        end
            resultvec(k) = -0.5*(signvec(1)-1)*(datamat(km,1)>=thr_mA) + 0.5*(signvec(1)+1)*(datamat(km,1)<thr_mA);
            if mod(k,100)==0
                km=km+16;
            end
            km=km+1;
    end
end
end

    
    

            

    
