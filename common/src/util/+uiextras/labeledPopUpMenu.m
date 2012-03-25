%Extension of the GUI Layout tool to have a labled pop-up menu.
function [tmpHBox, labelHandle, popUpMenuHandle] = labeledPopUpMenu(parentIn, labelString, menuTag, strings, size)

if nargin < 5
    size = [100, 25];
end
tmpHBox = uiextras.HButtonBox('Parent', parentIn, 'Spacing', 2, 'VerticalAlignment', 'middle');
labelHandle = uicontrol('Style', 'text',  'Parent', tmpHBox,  'HorizontalAlignment', 'right', 'FontSize', 10, 'String', labelString);
popUpMenuHandle = uicontrol('Style','popupmenu', 'Parent', tmpHBox, 'FontSize',10, 'BackgroundColor', [1,1,1], 'Tag', menuTag , 'String', strings);
tmpHBox.ButtonSize = size;       
