function savedatafig(dataobj)
    % FUNCTION savedatafig
    % takes in a data object created by loadData()
    % saveas the current figure to file with a nearly identical name (.out
    % -> .fig)
    
    saveas(gcf, fullfile(dataobj.path, strrep(dataobj.filename, '.h5', '.fig')));
    saveas(gcf, fullfile(dataobj.path, strrep(dataobj.filename, '.h5', '.png')));
end
    