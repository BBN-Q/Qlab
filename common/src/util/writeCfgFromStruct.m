% writeCfgFromStruct(file_name, params)
% Write experiment configuration to JSON file.
%
% Authors/Date : Blake Johnson and Colm Ryan / July 24, 2012

% Copyright 2012 Raytheon BBN Technologies
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

function writeCfgFromStruct(file_name, params)
    fid = fopen(file_name, 'w');
	fprintf(fid, '%s', jsonlab.savejson('',params));
    fclose(fid);
end