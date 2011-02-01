%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  writeCfgFromStruct.m
%
% Author/Date : Blake Johnson / October 19, 2010
%
% Description : Creates a config file from a structure of parameters by 
% performing a depth-first traversal of the input.
%
% Version: 1.1
%
%    Modified    By    Reason
%    --------    --    ------
%    12-13-2010  BRJ   Allow FID inputs in addition to string file names,
%                      to make this compatible with Exp.writeDataFileHeader
%
% Copyright 2010 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

function writeCfgFromStruct(file_name, instruct)
    if isnumeric(file_name)
        fid = file_name;
        closeFile = false;
    else
        fid = fopen(file_name, 'w');
        closeFile = true;
    end
	
	% depth first traversal of struct using a stack
	s = stack();
	% push a cell array composed of the base name and the input struct
	s.push({'' instruct});
	
	while ~s.isempty()
		u = s.pop();
		name = u{1};
		value = u{2};
		
		% if current element is itself a struct, add all its children to the
		% stack
		if isstruct(value)
			elementNames = fieldnames(value);
			len = numel(elementNames);
	
			for i = len:-1:1
				% record the hierarchy of names in first element of the cell
				% array
				if ~strcmp(name, '')
					namestack = [name '.' elementNames{i}];
				else
					namestack = elementNames{i};
				end
				s.push({namestack value.(elementNames{i})});
			end
		elseif ~isempty(value)
			fprintf(fid, '%s \t%s\n', name, almostany2str(value, true));
		end
	end

	% close cfg file
    if closeFile
        fclose(fid);
    end
end