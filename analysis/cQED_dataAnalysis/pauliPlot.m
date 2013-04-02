function pauliPlot(A)
    [~, pauliStrs] = paulis(1);
    cmap = [hot(50); 1-hot(50)];
    cmap = cmap(18:18+63,:); % make a 64-entry colormap
    figure()
    imagesc(A,[-1,1])
    colormap(cmap)
    colorbar()
    set(gca, 'XTick', 1:4);
    set(gca, 'XTickLabel', pauliStrs);
    set(gca, 'YTick', 1:4);
    set(gca, 'YTickLabel', pauliStrs);
    xlabel('Input Pauli Operator');
    ylabel('Output Pauli Operator');
end