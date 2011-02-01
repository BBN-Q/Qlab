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
myExp = main.Experiment.Expts.Skeleton('skeleton.cfg');

disp('Initializing experiment');
myExp.Initialize();

disp('Running experiment');
myExp.Run();

disp('Finalizing experiment');
myExp.Finalize();
