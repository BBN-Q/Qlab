function Data = FitResonance8720TO(filename,n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE:  Data = FitResonance8720TO(filename,n)
% Description: function to fit resonator data in filename for the nth trace 
% (must run parseDataFile_TO.m & have parse_ExpcfgFile_TO.m in path) 
% Returns the fit parameters and CFG file
% Input:   filename - file name in Rhys Hiltner's format 
%          n - nth scan in resontor data
% Output:  Matlab structure CFG which contains fields given in configuration 
%            file and their associated values and fit parameters
% v1.1  Tom Ohki January 10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

notifyoriteration = 'notify';

%fraction to guess Q from data
fraction = 0.94;

%redefine input structure for  nth fit 
expdata=filename;

%define input powers
% powersteps=expdata.CFG.LoopParams.some_loop.steps;
% powerin=linspace(expdata.CFG.ExpParams.meas_resp.power.start,expdata.CFG.ExpParams.meas_resp.power.end,powersteps);

%data points per sweep
points=expdata.CFG.InitParams.pna.ordered.sweep_points;

%center frequncy of PNA scan (Hz)
cfreq=expdata.CFG.ExpParams.meas_resp.sweep_center.start;

%span of PNA scan (Hz)
span=expdata.CFG.InitParams.pna.ordered.sweep_span;

% define frequency range
frequency=linspace(cfreq-span/2,cfreq+span/2,points);

% calculate S21Mag from real and imaginary parts of data
reald=expdata.Data(1:2:end,n)';
imagd=expdata.Data(2:2:end,n)';

% calculate S21 magnitude 
S21Mag=sqrt(reald.^2+imagd.^2);

% a bit of averaging
S21Mag=moving_average(S21Mag,3);
%plot(frequency,S21Mag,'.-');

% function to pick out r and zc for circle fit estimates ( must include
% fitting routine here for circle fit for various delay.  This shoukld only be done for
% only for the best SNR traces to extract Qc)
delay=34E-9;  % measured electrical delay on PNA  ( this is corrected for in hardware 
                % for some dataset)
                % signiture is a squashed or skew circle,  delay rotates
                % and reshapes this  but in theory this should be a fit
                % parameter that includes the circle fit routine.
ang=angle(reald+1i*imagd)+2*pi*frequency*delay;

x=S21Mag.*cos(ang);
y=S21Mag.*sin(ang);
[xc,yc,r,a] = circfit(x,y);
% [x1,y1] = ginput(1);
zc=sqrt(xc^2+yc^2);
% [x2,y2] = ginput(1);
t=linspace(0,2*pi,points);
xf=r.*cos(t)+xc;
yf=r.*sin(t)+yc;

fitS21Mag=sqrt(xf.^2+yf.^2);

subplot(1,2,1)
plot(x,y,xf,yf)
% r=sqrt((x1-x2)^2+(y1-y2)^2);



% Find resonance frequency
[minS21Mag, resfreqindex] = min(S21Mag);
% hold on
% plot(frequency(resfreqindex),S21Mag(resfreqindex),'r*')

% Guess the Q from raw data
% S213dbplus = max(S21Mag)*fraction;
% iindex1 = 1;
% while S21Mag(iindex1)>S213dbplus
%     iindex1 = iindex1+1;
% end
% f3dbminus = frequency(iindex1);
% iindex2 = length(S21Mag);
% while S21Mag(iindex2)>S213dbplus
%     iindex2 = iindex2-1;
% end
% f3dbplus = frequency(iindex2);
% deltaf = f3dbplus-f3dbminus;
%plot(frequency(iindex1),S21Mag(iindex1),'r*')
%plot(frequency(iindex2),S21Mag(iindex2),'r*')
% pause
f0Guess = frequency(resfreqindex);
slopeGuess = (S21Mag(end) - S21Mag(1))/span;
A0Guess = S21Mag(1) + slopeGuess*(f0Guess-frequency(1));
QrGuess = 2000;%f0Guess/deltaf;%2
S21minGuess = min(S21Mag);
%QcGuess = abs(QrGuess/(1-S21minGuess));
QcGuess=2000;
ThetaGuess = 310;
QiGuess = QcGuess*QrGuess/(QcGuess-QrGuess);

%FitParameterStart = [f0Guess A0Guess QrGuess QcGuess ThetaGuess];
%FitParameterStart = [f0Guess offset linear_slope amplitude skew Qr];
FitParameterStart = [f0Guess A0Guess slopeGuess 2e-003 1.5947e-015 QrGuess];
% Plot the initial guess and the data to see how bad initial guess is
[ChiSquaredInitialValue, GuessedS21] = ChiSqr(FitParameterStart, frequency, S21Mag);
subplot(1,2,2)
plot(frequency, (S21Mag),'.', frequency, GuessedS21,'r--','linewidth',3),axis tight
pause
% 
% Call the fitting function
options = optimset('LargeScale','off','MaxIter',10000, 'MaxFunEvals', 10000000,...
    'TolX', 1e-10, 'TolFun', 1e-10, 'Display', 'notify');
% [FitParameters] = ... 
%     fminsearch(@ChiSqr, FitParameterStart, options, frequency, S21Mag);
LB = [frequency(1) 1E-10 -1E-9 1E-15 -1E-10 1];
UB = [frequency(end) 1E-6 1E-9 1E-6 1E-10 1E6];

[FitParameters] = ... 
    fminsearchbnd(@ChiSqr, FitParameterStart, LB, UB, options, frequency, S21Mag);

% Plot final fits and the data together to see how bad the final fit is
[ChiSquaredMinimisedValue, PredictedS21,chisq] = ChiSqr(FitParameters, frequency, S21Mag);

Data.FitParameters = FitParameters';
% Data.fr = FitParameters(1);
% Data.A0 = FitParameters(2);
% Data.A1 = FitParameters(3);
% Data.A2 = FitParameters(4);
% Data.A3 = FitParameters(5);
Data.Qr= FitParameters(6);
Data.Qc=(zc+r)/(2*r)*Data.Qr;
Data.Qi= Data.Qr*Data.Qc/(Data.Qc-Data.Qr);
Data.chisq=chisq;
Data.PredictedS21=PredictedS21;
% Data.powerin=powerin;
subplot(1,2,2)
plot(frequency, (S21Mag),'.', frequency, sqrt(PredictedS21),'r--','linewidth',3),axis tight
% % 
% Fitting function
function [MinimiseThisFunction, S21Predict,chisq] = ChiSqr(FitParameter, g, S21)

% A0 = FitParameter(2);
% Qr = FitParameter(3); % Quality Factor
% Qc = FitParameter(4);
% theta = FitParameter(5);
f0 = FitParameter(1); % Resonance Frequency
A0 = FitParameter(2); % offset
A1 = FitParameter(3); % linear slope
A2 = FitParameter(4); % Lorentzian amplitude
A3 = FitParameter(5); % Lorentzian slope
Qr = FitParameter(6); % Quality Factor
%S21Predict = abs((A0)*exp(2*pi*1i*g*30E-9).*(1-Qr/Qc*exp(1i*theta*pi/180)*1./(1+2*Qr*1i*(g/f0-1))));
%S21Predict = abs((A0).*(1-Qr/Qc*exp(1i*theta*pi/180)*1./(1-2*Qr*1i*(g-f0/f0))));
%S21Predict = abs((A0).*(1-Qr/Qc*exp(1i*theta*pi/180)*1./(1+Qr*1i*(g/f0-1).*(f0./g+1))));
% skewed lonrenztian fit to Gao thesis to extract Qr.
S21Predict = A0+A1*(g-f0)-(A2-A3*(g-f0))./(1+4*Qr.^2*((g-f0)/f0).^2);
% absolute square of this function not just absolute
MinimiseThisFunction = sum((S21Predict - (abs(S21)).^2).^2);
chisq = sum((S21Predict - (abs(S21)).^2).^2./S21Predict);

% 
%%plot(g, (abs(S21)).^2,'.', g, S21Predict); drawnow;
% % plot(weight); drawnow; pause;