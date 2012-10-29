function varargout = bgsubtractImage(h)
    % FUNCTION bgsubtractImage(handle h)
    % Subtracts the background from the figure with handle h. If no handle is
    % provided, assumes the current figure
    
    if nargin < 1
        h = gcf;
    end
    
    %Grab the image handle
    imgHandle = findobj(h, 'Type', 'Image');
    
    if isempty(imgHandle)
        error('NO IMAGE: Could not find an image object in the figure.')
    end

    %Update the image data
    set(imgHandle, 'CData', bgsubtract(get(imgHandle, 'CData')));
    
    if nargout == 1
        varargout{1} = get(imgHandle, 'CData');
    end
end