%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Hack COSTM script for OST testing
%simple dc measurement script for IV

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%     CLEAR      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
temp = instrfind;
if ~isempty(temp)
    fclose(temp)
    delete(temp)
end
clear temp

clear i tempnum tempavg voltage dvoltage current j temp
%close all
%fclose all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     INITIALIZE PATH     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

base_path = 'C:\Qlab software\experiments\Graphene\';
cd(base_path)
addpath([ base_path,'data'],'-END');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%     INITIALIZE  EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Connect to Tektronix AFG 3102 Signal Generator
sigGen = deviceDrivers.TekAFG3102();
sigGen.connect('1');
%Connect to Spectrum Analyser HP71000
spec = deviceDrivers.HP71000();
spec.connect('18')
spec.centerFreq = 0.02; %in GHz
spec.span = 30000000;   %in Hz

%%%%%%%%%
%run information
startFreq = 1000000 % in Hz
endFreq = 1000000 % in Hz
stepsFreq = 1 % number of frequency points taken

startAmp = 1 % in Vrms
endAmp = 0.01 % in Vrms
stepsAmp = 10 % number of voltAge steps to take
logSteps = 1 % take log voltage steps? (1=log , 0=Linear)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%     RUN THE EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:stepsFreq
    sigGen.frequency = startFreq+i*(endFreq-startFreq)/n
    for j=1:stepsAmp
        if logSteps = 1
            sigGen.rmsAmp = exp[log[



for i=1:4*num
       %set current
 
       %fprintf(KCS,sprintf('I%sX',num2str(current(i))));
       fprintf(YCS,sprintf(':SOURCE:LEVEL %s',num2str(current(i))));
       %fprintf(KM,'S9X');
       
       pause(4)
       % readout average voltage voltage
       
       for j=1:numavg    
       fprintf(KM,'Read?')
       temp=fgetl(KM);
       tempnum(j)=str2num(temp(5:end));
%        subplot(2,1,1)
%        plot(current(i),tempnum(j),'.b');
%        hold on
       end
     
%        %background calibration
%        fprintf(KCS,sprintf('I%sX',num2str(.000)));
%        pause(5)
%        % readout average BACKGROUND voltage
%        for j=1:numavg    
%        fprintf(KM,'Read?')
%        tempb=fgetl(KM);
%        tempnumb(j)=str2num(tempb(5:end));
%        end

       tempavg=sum(tempnum)/numavg;
       subplot(2,1,1)
       voltage(i)=tempavg;
       plot(current(i),voltage(i),'.k');
       hold on
%        %DERIVATIVE CALC
%        if (i>1)&&(i<=num)
%            dvoltage(i)=(voltage(i)-voltage(i-1))/step;
%            subplot(2,1,2)
%        plot(current(i),dvoltage(i),'.r');
%        hold on
%        elseif i>(num+1)
%            dvoltage(i)=(voltage(i-1)-voltage(i))/step;
%            subplot(2,1,2)
%            plot(current(i),dvoltage(i),'.k');
%        else
%        end
       if (i>=1)&&(i<=num)
           dvoltage(i)=(voltage(i)/10)/(current(i)/1000);
           subplot(2,1,2)
       plot(current(i)/1000,dvoltage(i),'.r');
       hold on
       elseif i>=(num+1)
           dvoltage(i)=(voltage(i)/10)/(current(i)/1000);
           subplot(2,1,2)
           plot(current(i)/1000,dvoltage(i),'.b');
       else
       end
       
      
end
% subplot(2,1,2)
% plot(current(1:num),(voltage(1:num)-fliplr(voltage(num+1:end)))/step/100)
fprintf(YCS,':SOURCE:LEVEL 0E-3');
fprintf(YCS,':OUTPUT off')     
%fprintf(KCS,'F0X');     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       PLOT AND SAVE DATA     %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% hold off
% xlabel('Current (A)')
% ylabel('Voltage (V)')

fclose(YCS);
fclose(KM);
delete(YCS);
delete(KM);


