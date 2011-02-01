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
%addpath('C:\Documents and Settings\gbrummer\Desktop\Code\BBN_Experiment')
addpath('data');
addpath('src');

dummyExp = Dummy('dummyv2.cfg');

disp('Initializing experiment');
dummyExp.Initialize();

disp('Running experiment');
dummyExp.Run();

disp('Finalizing experiment');
dummyExp.Finalize();
