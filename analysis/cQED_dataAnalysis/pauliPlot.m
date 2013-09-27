function pauliPlot(A, nbrQubits)
    [~, pauliStrs] = paulis(nbrQubits);
    % sort by "hamming" weight of the pauli operator
    weights = cellfun(@pauliHamming, pauliStrs);
    [~, weightIdx] = sort(weights);
    pauliStrs = pauliStrs(weightIdx);
    A = A(weightIdx, weightIdx);
    cmap = [hot(50); 1-hot(50)];
    cmap = cmap(18:18+63,:); % make a 64-entry colormap
    figure()
    imagesc(A,[-1,1])
    colormap(cmap)
    colorbar()
    set(gca, 'XTick', 1:4^nbrQubits);
    set(gca, 'XTickLabel', pauliStrs);
    set(gca, 'YTick', 1:4^nbrQubits);
    set(gca, 'YTickLabel', pauliStrs);
    xlabel('Input Pauli Operator');
    ylabel('Output Pauli Operator');
end

function weight = pauliHamming(str)
    weight = 0;
    for pauli = str
        if ~strcmp(pauli, 'I')
            weight = weight + 1;
        end
    end
end
    