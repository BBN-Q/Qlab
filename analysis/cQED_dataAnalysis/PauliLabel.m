function PauliLabel()
    axis([0.5, 16.5,-1.25, 1.25]); 
    %xlabel('Pauli set');
    set(gca, 'XTick', 1:1:16);
    set(gca, 'XTickLabel', {'II', 'XI', 'YI', 'ZI', 'IX', 'IY', 'IZ', 'XY', 'XZ', 'YX', 'YZ', 'ZX', 'ZY', 'XX', 'YY', 'ZZ'});
end