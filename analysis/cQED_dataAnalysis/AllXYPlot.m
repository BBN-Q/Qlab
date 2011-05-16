function AllXYPlot(data)
    % compute scale factor
    yscale = (max(data.phase_Data) - mean(data.phase_Data(1:2)))/2;
    ypts = ( data.phase_Data - mean(data.phase_Data(1:2)) )/yscale - 1;
    
    h = gcf;
    clf
    h = plot(ypts, '.-');
    ylim([-1.1 1.1])
    set(gca, 'YTick', [-1:.5:1])
    AllXYlabel(h);
    title(strrep(data.filename, '_', '\_'))
    ylabel('<\sigma_z>')
    grid on
end