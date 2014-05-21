function pauliSetPlot(pauliVec)

nbrQubits = log2(length(pauliVec))/2;
[~, pauliStrs] = paulis(nbrQubits);

% sort by "hamming" weight of the pauli operator
weights = cellfun(@pauliHamming, pauliStrs);
[~, weightIdx] = sort(weights);
pauliStrs = pauliStrs(weightIdx);
pauliVec = pauliVec(weightIdx);

figure();
bar(pauliVec);
axis([0.5, length(pauliVec)+0.5,-1.1, 1.1]); 
set(gca, 'XTick', 1:length(pauliStrs));
set(gca, 'XTickLabel', pauliStrs);

end

