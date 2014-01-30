function records = read_records(fileName)
%read_records Read single-shot records from file.
%
% records = read_records(fileName)

    %Open the real and imaginary files and then combine
    records = read_file([fileName, '.real']) +1j*read_file([fileName, '.imag']);
end

function data = read_file(myFileName)
    fid = fopen(myFileName, 'rb');
    sizes = fread(fid,3, 'int32');
    data = fread(fid, inf, 'single=>single');
    lastDim = length(data)/prod(sizes);
    data = reshape(data, [sizes; lastDim]');
    fclose(fid);
end

