function [errorMsg] = writeDataFileHeader(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%USAGE: [errorMsg] = write_DataFileHeader(obj)
%
%Description: This function prints all of the data in 'structure' into the
%file attached to the handle fid.  This function is meant to be fully
%compatible with parse_ExpcfgFile.m, so that 'structure' could be fully
%recreated by running parse_ExpcfgFile.m on the resultant file.
%
%Limitations:  All fields must be 1)numeric arrays for not more than 2
%dimensions, 2)Strings, or 3) cells of strings with not more than 2
%dimensions.  Data must be entered as comma seperated values with no spaces 
%and ';' used to denote line breaks in 2 dimensional data.  Equals signs 
%should not be used  Quotes should NOT be put around strings unless they 
% are being included in a cell.  So:
%
% pulse_device  Tektronix5000
%
% works, but 
%
% pulse_device 'Tektronix5000'
%
% doesn't.  And a cell is input like this:
%
% pulse_devices {'Tektronix5000','BBN','Agilent'}
%
% v1.1 9 JULY 2009 William Kelly <wkelly@bbn.com>
% v2.0 13 DEC 2010 Blake Johnson <bjohnson@bbn.com>
% Now uses the more robust writeCfgFromStruct method.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

errorMsg = '';

% labels that indicated the beginning and end of the cfg header
StartHeader = '$$$ Beginning of Header';
EndHeader   = '$$$ End of Header';

structure = obj.inputStructure;
fid       = obj.DataFileHandle;
try
    %fprintf(fid,'\n');
    fprintf(fid,'%s\n',StartHeader);
    writeCfgFromStruct(fid, structure);
    fprintf(fid,'%s\n',EndHeader);
catch ErrorStruct
    errorMsg = ErrorStruct.message;
end