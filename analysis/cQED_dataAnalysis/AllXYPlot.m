function AllXYPlot(data, ampPhase)
    if ~exist('ampPhase', 'var')
        ampPhase = 'phase';
    end
    if strcmp(ampPhase, 'amp')
        plotData = data.abs_Data;
    else
        plotData = data.phase_Data;
    end
    
    % average together pairs of data points
    plotData = (plotData(1:2:end) + plotData(2:2:end))/2;
    % compute scale factor
    yscale = (max(plotData) - plotData(1))/2;
    ypts = ( plotData - plotData(1) )/yscale - 1;
    
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