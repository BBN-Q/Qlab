function [fs1] = listFieldNames(s1,n1)
% check two structures for differances - i.e. see if strucutre s1 == structure s2
% function [fs1, er] = comp_struct(s1,s2,n1,n2,p,tol)
%
% inputs  6 - 5 optional
% s1      structure one                              class structure
% n1      first structure name (variable name)       class char - optional
%
% outputs 3 - 3 optional
% fs1     non-matching feilds for structure one      class cell - optional
%
% This function will recursively acquire the field names from nested
% strucutures.
%
% This function is a modified version of comp_struct.m found on the MatLab
% file exchange http://www.mathworks.co.uk/matlabcentral/fileexchange/22752
%
% modified by William Kelly <wkelly@bbn.com> on 10 JULY 2009
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 1; n1 = '';end
if nargin < 1; help listFieldNames; error('I / O error'); end
% define fs
fs1 = {};

% are the variables structures
if isstruct(s1)
    fn1 = fieldnames(s1);
    pnt1i = 1:numel(fn1);
    for ii=1:numel(pnt1i)
        %		added loop for indexed structured variables
        for jj = 1:size(s1,2)
            %			clean display - add index if needed
            if size(s1,2) == 1
                n1p = [n1 char(fn1(pnt1i(ii))) '.'];
            else
                n1p = [n1 '(' num2str(jj) ').' char(fn1(ii))];
            end
            [fss1] = listFieldNames(getfield(s1(jj),char(fn1(pnt1i(ii)))), ...
                n1p);
            fs1 = [fs1; fss1];
        end
    end
else
    fs1 = [fs1 sprintf('%s',n1)];
end