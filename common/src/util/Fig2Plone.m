function Fig2Plone(figHandle, dataObj, imageDescrip, username, password, storeDate)
%Fig2Plone(figHandle, dataObj, imageDescrip, username, password, date)
%
% Bridge function to Python functions to push image to the Plone site
%
% Date is a string in the format '22-Mar-2012'
% If date is not defined then default to today.

ploneSite = 'echelon.bbn.com:8080/QLab';

%Save the figure handle as a Matlab figure and .png (I'd really like to
%move to svg).  See also savedatafig
saveas(figHandle, [dataObj.path strrep(dataObj.filename, '.out', '.fig')]);
imageFile = [dataObj.path strrep(dataObj.filename, '.out', '.png')];
saveas(figHandle, imageFile)

%Default to today's date
if nargin < 6
    storeDate = date;
end

%Now pass off to the python script. 
[status, result] = system(sprintf(...
    'pythonw "%s" --ploneSite "%s" --username "%s" --password "%s" --imageFile "%s" --imageDescrip "%s" --date "%s"',...
    fullfile(fileparts(mfilename('fullpath')), 'Fig2Plone.py'), ploneSite, username, password, imageFile, imageDescrip, storeDate));

assert(status==0, 'Oops, the Python script seems to have failed out:\n %s',result);

%Print out how to link to the figure
disp(result)

end
