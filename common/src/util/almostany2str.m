function str = almostany2str(Value,noQuotes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%USAGE: str = almostany2str(Value)
%
%Description: This function will take in (almost) any matlab variable and
%return a string such that eval(almostany2str(Value)) returns value.
%
%v1.1 10 JUNE 2010 William Kelly <wkelly@bbn.com>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('noQuotes','var')
    noQuotes = false;
end
if isnumeric(Value)
    array = Value;
    if isempty(array)
        str = '[]';
    elseif isscalar(array)
        str = sprintf('%.7g',array);
    else
        if ndims(array) > 2
            error('CFG files may not contain arrays with more than 2 dimenstions')
        end
        str = mat2str(array);
    end
elseif ischar(Value)
    if isempty(Value)
        if noQuotes
            str = '';
        else
            str = '''''';
        end
    else
        if noQuotes
            str = sprintf('%s',Value);
        else
            str = sprintf('''%s''',Value);
        end
    end
elseif iscellstr(Value)
    CellStr = Value;
    if isempty(CellStr)
        str = '{}';
    else
        if ndims(Value) > 2
            error('CFG files may not contain cells with more than 2 dimenstions')
        end
        str = '{';
        CellStrSize = size(CellStr);
        for rowIndex = 1:CellStrSize(1)
            for columnIndex = 1:(CellStrSize(2))
                str = [str sprintf('''%s'',',cell2mat(CellStr(rowIndex,columnIndex)))];
            end
            if rowIndex == CellStrSize(1)
                str = [str '}'];
            else
                str = [str ';'];
            end
        end
    end
elseif iscell(Value)
    Cell = Value;
    if isempty(Cell)
        str = '{}';
    else
        str = '{';
        if ndims(Value) > 2
            error('CFG files may not contain cells with more than 2 dimenstions')
        end
        CellSize = size(Cell);
        for rowIndex = 1:CellSize(1)
            for columnIndex = 1:(CellSize(2))
                value = cell2mat(Cell(rowIndex,columnIndex));
                if ischar(value)
                    str = [str sprintf('''%s'',',value)];
                elseif isnumeric(value) && isscalar(value)
                    str = [str sprintf('%.7g,',value)];
                else
                    error('cell contents must be scalars or strings')
                end
            end
            if rowIndex == CellSize(1)
                str = [str '}'];
            else
                str = [str ';'];
            end
        end
    end
else
    error('unsuported data type')
end

end