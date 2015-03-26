    PtoAP = zeros(length(tMat),8);
    APtoP = zeros(length(tMat),8);
for ct1 = 1:8
    tMat=allTransitionMats{ct1};
    for ct2 = 1:length(PtoAP)
        curMat = tMat{ct2};
        PtoAP(ct2,ct1) = curMat(2,1)/sum(curMat(:,1));
        APtoP(ct2,ct1) = curMat(1,2)/sum(curMat(:,2));
    end
end