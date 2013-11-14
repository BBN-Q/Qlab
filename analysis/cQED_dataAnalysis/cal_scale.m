function data = cal_scale(varargin)
    % FUNCTION cal_scale(varargin)
    % Rescales the data by the pi and 0 calibration experiments at the end.
    % Inputs:
    % (data/plotGrab) - raw data set to calibrate or choose the "one", "top" or "bottom" to grab from current figure 
    % (numRepeats) - number of times calibration experiments are repeated (default: 2)
    
    %Check if we have data in or whether we are grabbing from a plot
    if isnumeric(varargin{1})
        data = varargin{1};
        if nargin < 2
            numRepeats = 2;
        else
            numRepeats = varargin{2};
        end
        xlab = ''; ylab = ''; figTitle = '';
    elseif ischar(varargin{1})
        axesHs = findobj(gcf, 'Type', 'Axes');
        switch varargin{1}
            case 'bottom'
                axesH = axesHs(2);
            case {'top','one'}
                axesH = axesHs(1);
            otherwise
                error('Unknown plot grab command.');
        end
        % grab the line handle
        lineHandle = findobj(axesH, 'Type', 'Line');
        assert(~isempty(lineHandle), 'NO DATA: Could not find an line object in the figure.')
        xpts = get(lineHandle(1), 'XData');
        data = get(lineHandle(1), 'YData');
        if nargin < 2
            numRepeats = 2;
        else
            numRepeats = varargin{2};
        end
        
        % save axis labels and figure title
        xlab = get(get(axesH, 'XLabel'), 'String');
        ylab = get(get(axesH, 'YLabel'), 'String');
        figTitle = get(get(axesH, 'Title'), 'String');
    else
        error('First argument should be data or plotGrab string.')
    end
    
    % extract calibration experiments
    switch nsdims(data)
        case 1
            zeroCal = mean(data(end-2*numRepeats+1:end-numRepeats));
            piCal = mean(data(end-numRepeats+1:end));
            scaleFactor = (piCal - zeroCal)/2;
            data = data(1:end-2*numRepeats);
            data = (data - zeroCal)./scaleFactor - 1;
    
        case 2
            zeroCal = mean(data(:, end-2*numRepeats+1:end-numRepeats), 2);
            piCal = mean(data(:, end-numRepeats+1:end), 2);
            scaleFactor = (piCal - zeroCal)/2;

            data = data(:, 1:end-2*numRepeats);
            data = bsxfun(@rdivide, bsxfun(@minus, data, zeroCal), scaleFactor) - 1;
            
        otherwise
            error('Unable to handle dimensions of data')
    end
    
    if exist('axesH', 'var')
        xpts = xpts(1:end-2*numRepeats);

        % save axis labels and figure title
        xlab = get(get(axesH, 'XLabel'), 'String');
        ylab = get(get(axesH, 'YLabel'), 'String');
        figTitle = get(get(axesH, 'Title'), 'String');

        % create the new plot
        figure()
        plot(xpts, data);
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
    end
    
end