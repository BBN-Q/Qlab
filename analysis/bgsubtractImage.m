function varargout = bgsubtractImage(h)
    % FUNCTION bgsubtractImage(handle h)
    % Subtracts the background from the figure with handle h. If no handle is
    % provided, assumes the current figure
    
    if nargin < 1
        h = gcf;
    end
    
    % grab the image handle
    imgHandle = findobj(h, 'Type', 'Image');
    
    if isempty(imgHandle)
        error('NO IMAGE: Could not find an image object in the figure.')
    end
    
    xpts = get(imgHandle, 'XData');
    ypts = get(imgHandle, 'YData');
    zpts = get(imgHandle, 'CData');
    
    % subtract the background
    zpts = bgsubtract(zpts);
    
    % save axis labels and figure title
    axesH = findobj(h, 'Type', 'axes');
    xlab = get(get(axesH, 'XLabel'), 'String');
    ylab = get(get(axesH, 'YLabel'), 'String');
    figTitle = get(get(axesH, 'Title'), 'String');
    
    % create the new plot
    figure(h)
    imagesc(xpts, ypts, zpts);
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
        varargout{1} = zpts;
    end
end