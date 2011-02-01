function fitstamp(data)
    %FITSTAMP labels a plot with the loaded filename in data.filename
    subplot(3,1,1)
    title(strrep(data.filename, '_', '\_'))
end

