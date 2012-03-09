clear all;
close all;
fclose('all');

disp('Closing instruments');
tmp=instrfind;
if ~isempty(tmp)
    fclose(tmp);
    delete(tmp);
end
clear tmp;

clear classes;

disp('Creating experiment');

%addpath('C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\BBN_Experiment')
%addpath('U:\Tom\BBN_Experiment')
addpath('data');
addpath('src');
import Dummy.*
dummyExp = Dummy('dummy3.cfg');

disp('Initializing experiment');
dummyExp.Initialize();

disp('Running experiment');
dummyExp.Run();

disp('Finalizing experiment');
dummyExp.Finalize();
