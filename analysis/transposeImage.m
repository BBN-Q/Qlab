function transposeImage(h)
    % FUNCTION tranposeImage(handle h)
    % Transposes an image in the figure with handle h. If no handle is
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
    
    % save axis labels and figure title
    axesH = findobj(h, 'Type', 'axes');
    xlab = get(get(axesH, 'XLabel'), 'String');
    ylab = get(get(axesH, 'YLabel'), 'String');
    figTitle = get(get(axesH, 'Title'), 'String');
    
    % create the new plot
    figure(h)
    imagesc(ypts, xpts, zpts');
    set(gca, 'YDir', 'normal');
    if ~isempty(ylab)
        xlabel(ylab)
    end
    if ~isempty(xlab)
        ylabel(xlab)
    end
    if ~isempty(figTitle)
        title(figTitle)
    end
end