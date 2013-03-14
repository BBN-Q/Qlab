function out = nsdims(A)
    % nsdims(A) finds the number of non-singleton dimensions of A
    sizeA = size(A);
    sizeA(sizeA == 1) = [];
    out = length(sizeA);
end