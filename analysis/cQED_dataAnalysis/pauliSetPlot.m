function pauliSetPlot(pauliVec, varargin)

nbrQubits = log2(length(pauliVec))/2;
[~, pauliStrs] = paulis(nbrQubits);

% sort by "hamming" weight of the pauli operator
weights = cellfun(@pauliHamming, pauliStrs);
[~, weightIdx] = sort(weights);
pauliStrs = pauliStrs(weightIdx);
pauliVec = pauliVec(weightIdx);

if nargin>1
    figure(varargin{1}); clf;
else 
    figure();
end
bar(pauliVec);
axis([0.5, length(pauliVec)+0.5,-1.1, 1.1]); 
set(gca, 'XTick', 1:length(pauliStrs));
set(gca, 'XTickLabel', pauliStrs);

end

