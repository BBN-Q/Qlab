% plot Syracuse resonator measurement vs temperature
basepath = '/Users/bjohnson/Dropbox/MATLAB/qlab/experiments/Resonator/data/Syracuse Resonators - Jan 18 2011/110119/';
temp = dir(basepath);
tindex = 1;

% remove non-directories
for i = 1:length(temp)
    if temp(i).isdir && ~(strcmp(temp(i).name, '.') || strcmp(temp(i).name, '..'))
        tempdirs{tindex} = temp(i).name;
        tindex  = tindex + 1;
    end
end

% convert directory names into values
temperatures = zeros(size(tempdirs));
for i = 1:length(tempdirs)
    tokens = regexp(tempdirs{i}, '(\d)p(\d)+K', 'tokens');
    temperatures(i) = str2num(sprintf('%d.%d\n', [str2num(tokens{1}{1}), str2num(tokens{1}{2})]));
end

% grab data files in temperature directories
for i = 1:length(tempdirs)
    file1 = dir([basepath tempdirs{i} '/*3p4*.out']);
    file2 = dir([basepath tempdirs{i} '/*3p6*.out']);
    file3 = dir([basepath tempdirs{i} '/*3p9*.out']);
    file4 = dir([basepath tempdirs{i} '/*4p2*.out']);
    file5 = dir([basepath tempdirs{i} '/*4p3*.out']);
    
    for j = 1:5
        data{j}{i} = parseDataFile_TO( [basepath tempdirs{i} '/' eval(['file' num2str(j) '.name'])] );
    end
end