function plot_switching_probs(tMat, axesH, xaxis)
%Plots switching probabilities given a cell array of 2x2 transition events

PtoAP = zeros(length(tMat),1);
APtoP = zeros(length(tMat),1);

for ct = 1:length(PtoAP)
    curMat = tMat{ct};
    PtoAP(ct) = curMat(2,1)/sum(curMat(:,1));
    APtoP(ct) = curMat(1,2)/sum(curMat(:,2));
end

plot(axesH, xaxis, PtoAP);
hold on;
plot(axesH, xaxis, APtoP, 'r');
ylabel('Switching Probability');
legend({'P->AP', 'AP-P'});

end
