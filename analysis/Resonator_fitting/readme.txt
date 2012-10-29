%%%All *.m files must be in your path

%%%%parseDataFile_TO.m  is a function to read in Hiltners data file format
%%%%(I know we should have a standard one but he did not listen)

%%Ex.  

newdata=parseDataFile_TO('Dummy_data_20100121T104210.out');

%%%Dummy_data_20100121T104210.out is a example data file

%%%This will spit out a structure newdata that has everything in it and it will also
%%%display the number of matrix elements we are dealing with

%%Ex.  
FitResonance8720TOnew(newdata,1)

%% gives you the fit for the n=1 elemnt of the array.

