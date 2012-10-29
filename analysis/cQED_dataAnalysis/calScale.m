function varargout = calScale(ampPhase, dupFactor, h)
    % FUNCTION calScale(dupFactor, handle h)
    % Rescales the data in figure h by the pi and 0 calibration experiments at the end.
    % Inputs:
    % ampPhase - choose the amplitude (amp) or phase (phase) data subplot (optional, default: 'amp')
    % dupFactor - number of times calibration experiments are repeated (default: 2)
    % h - handle with the data, if not given assume the current figure
    
    if ~exist('ampPhase', 'var')
        ampPhase = 'amp';
    end
    if ~exist('dupFactor', 'var')
        dupFactor = 2;
    end
    if ~exist('h', 'var')
        h = gcf;
    end
    
    % choose the amplitude or phase axis (if there are two)
    objs = findobj(gcf, 'Type', 'Axes');
    if length(objs) == 1
        axesH = objs(1);
        titleH = axesH;
    elseif length(objs) == 2
        titleH = subplot(2,1,1);
        if strcmp(ampPhase, 'amp')
            axesH = subplot(2,1,1);
        else strcmp(ampPhase, 'phase')
            axesH = subplot(2,1,2);
        end
    else
        error('More than two subplots')
    end
    % grab the line handle
    lineHandle = findobj(axesH, 'Type', 'Line');
    
    if isempty(lineHandle)
        error('NO DATA: Could not find an line object in the figure.')
    end
    
    xpts = get(lineHandle(1), 'XData');
    ypts = get(lineHandle(1), 'YData');
    
    % extract calibration experiments
    zeroCal = mean(ypts(end-2*dupFactor+1:end-dupFactor));
    piCal = mean(ypts(end-dupFactor+1:end));
    scaleFactor = (piCal - zeroCal)/2;
    xpts = xpts(1:end-2*dupFactor);
    ypts = ypts(1:end-2*dupFactor);
    
    % rescale
    ypts = (ypts - zeroCal)./scaleFactor - 1;
    
    % save axis labels and figure title
    xlab = get(get(axesH, 'XLabel'), 'String');
    ylab = get(get(axesH, 'YLabel'), 'String');
    figTitle = get(get(titleH, 'Title'), 'String');
    
    % create the new plot
    figure(h)
    clf(h);
    plot(xpts, ypts);
    set(gca, 'YDir', 'normal');
    if ~isempty(xlab)
        xlabel(xlab)
    end
    if ~isempty(ylab)
        ylabel(ylab)
    end
    if ~isempty(figTitle)
        title(figTitle)
    end
    
    if nargout == 1
        varargout{1} = ypts;
    elseif nargout == 2
        varargout{1} = xpts;
        varargout{2} = ypts;
    end
end