function AllXYPlot(data, ampPhase)
    if ~exist('ampPhase', 'var')
        ampPhase = 'amp';
    end
    if strcmp(ampPhase, 'amp')
        plotData = data.abs_Data;
    else
        plotData = data.phase_Data;
    end
    
    % average together pairs of data points
    plotData = (plotData(1:2:end) + plotData(2:2:end))/2;
    % compute scale factor
    yscale = -(mean(plotData(28:35)) - plotData(1))/2;
    ypts = ( plotData - plotData(1) )/yscale + 1;
    
    h = gcf;
    clf
    %h = plot(ypts, '.-');
    h = barh(flipud(ypts));
    ylim([0 36])
    xlim([-1.15 1.15])
    set(gca, 'XTick', [-1:.5:1])
    AllXYlabel(h);
    title(strrep(data.filename, '_', '\_'))
    xlabel('<\sigma_z>')
end