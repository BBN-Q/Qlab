function pauliSetPlot(pauliVec, varargin)

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

nbrQubits = log2(length(pauliVec))/2;
[~, pauliStrs] = paulis(nbrQubits);

% sort by "hamming" weight of the pauli operator
weights = cellfun(@pauliHamming, pauliStrs);
[~, weightIdx] = sort(weights);
pauliStrs = pauliStrs(weightIdx);
pauliVec = pauliVec(weightIdx);

if ~isempty(varargin)
    if ~isfield(figHandles, varargin{1}) || ~ishandle(figHandles.(varargin{1}))
        figHandles.(varargin{1}) = figure('Name', varargin{1});
    else
        figure(figHandles.(varargin{1})); clf;
    end
else
    figure();
end
bar(pauliVec);
axis([0.5, length(pauliVec)+0.5,-1.1, 1.1]); 
set(gca, 'XTick', 1:length(pauliStrs));
set(gca, 'XTickLabel', pauliStrs);

end

