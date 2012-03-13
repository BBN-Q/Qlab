%Extension of GUI Layout tool to put together a label and an edit box in a
%HButtonBox

function [tmpHBox, labelHandle, editBoxHandle] = labeledEditBox(parentIn, labelString, editBoxTag, defaultString, size)

if nargin < 5
    size = [100, 25];
end
tmpHBox = uiextras.HButtonBox('Parent', parentIn, 'Spacing', 2, 'VerticalAlignment', 'middle');
labelHandle = uicontrol('Style', 'text',  'Parent', tmpHBox,  'HorizontalAlignment', 'right', 'FontSize', 10, 'String', labelString);
editBoxHandle = uicontrol('Style','edit','Parent', tmpHBox, 'FontSize', 10, 'HorizontalAlignment', 'right', 'BackgroundColor', [1,1,1], 'Tag', editBoxTag , 'String', defaultString);
tmpHBox.ButtonSize = size;       

