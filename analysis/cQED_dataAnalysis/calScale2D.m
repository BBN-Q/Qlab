function calScale2D(nbrRepeats)

if ~exist('nbrRepeats', 'var')
    nbrRepeats = 2;
end
h = gcf;
% grab the image handle
imgHandle = findobj(h, 'Type', 'Image');

if isempty(imgHandle)
    error('NO IMAGE: Could not find an image object in the figure.')
end

xpts = get(imgHandle, 'XData');
ypts = get(imgHandle, 'YData');
zpts = get(imgHandle, 'CData');
zpts_scaled = zeros(size(zpts,1), size(zpts,2)-2*nbrRepeats);

% calScale each row
for row = 1:size(zpts,1)
    rowdata = zpts(row,:);
    % extract calibration experiments
    zeroCal = mean(rowdata(end-2*nbrRepeats+1:end-nbrRepeats));
    piCal = mean(rowdata(end-nbrRepeats+1:end));
    scaleFactor = (piCal - zeroCal)/2;
    
    % rescale
    zpts_scaled(row,:) = (rowdata(1:end-2*nbrRepeats) - zeroCal)./scaleFactor - 1;
end

% save axis labels and figure title
axesH = findobj(h, 'Type', 'axes');
xlab = get(get(axesH, 'XLabel'), 'String');
ylab = get(get(axesH, 'YLabel'), 'String');
figTitle = get(get(axesH, 'Title'), 'String');

% create the new plot
%figure(h)
figure
imagesc(xpts(1:end-2*nbrRepeats), ypts, zpts_scaled);
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