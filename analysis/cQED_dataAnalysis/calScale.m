function varargout = calScale(dupFactor, h)
    % FUNCTION calScale(dupFactor, handle h)
    % Rescales the data in figure h by the pi and 0 calibration experiments at the end.
    % Inputs:
    % dupFactor - number of times calibration experiments are repeated (default: 2)
    % h - handle with the data, if not given assume the current figure
    
    if ~exist('dupFactor', 'var')
        dupFactor = 2;
    end
    if ~exist('h', 'var')
        h = gcf;
    end
    
    % grab the line handle
    lineHandle = findobj(h, 'Type', 'Line');
    
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
    axesH = findobj(h, 'Type', 'axes');
    xlab = get(get(axesH, 'XLabel'), 'String');
    ylab = get(get(axesH, 'YLabel'), 'String');
    figTitle = get(get(axesH, 'Title'), 'String');
    
    % create the new plot
    figure(h)
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
        varargout(1) = ypts;
    elseif nargout == 2
        varargout(1) = xpts;
        varargout(2) = ypts;
    end
end