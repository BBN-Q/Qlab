% helper function to get the selected menu object text

function selected = get_selected(hObject)
	menu = get(hObject,'String');
	selected = menu{get(hObject,'Value')};
end