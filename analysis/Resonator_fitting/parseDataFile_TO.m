function data = parseDataFile(filename)

CFG = parse_ExpcfgFile_TO(filename);

fid = fopen(filename);

startData = 0;
index1 = 1;

while 1
    line = fgetl(fid);
    if strfind(line,'$$$ Beginning of data')
        startData = 1;
        continue;
    end
    if startData
        if strfind(line,'$$$ End of data')
            if startData == 0
                Data = [];
            end
            break;
        else
            if isempty(line)
                continue
            elseif line == -1
                break
            else
                temp = str2num(line);
                Data(1:length(temp),index1) = temp;
                index1 = index1+1;
            end

        end
    end
end

data.CFG  = CFG;
data.Data = Data;
samples=size(data.Data,1)
nvalues=size(data.Data,2)

