function weight = pauliHamming(str)
    weight = 0;
    for pauli = str
        if ~strcmp(pauli, 'I')
            weight = weight + 1;
        end
    end
end