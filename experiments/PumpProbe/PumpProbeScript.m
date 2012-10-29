% fluxStart = 0.0;
% fluxStep = 0.4;%changed 121005 HP
% fluxStop = 2;%4.0;
% fluxBiases = fluxStart:fluxStep:fluxStop;

% fluxStart = 0.0;
% fluxStep = 2;%changed 121005 HP
% fluxStop = 2;%4.0;
% fluxBiases = fluxStart:fluxStep:fluxStop;
fluxBiases = 0;

% pumpStart = 6.4;
% pumpStep = 0.1;
% pumpStop = 6.6;%7.5;
% pumpFreqs = pumpStart:pumpStep:pumpStop;

%pumpFreqs(:,1) = [6.4, 6.5, 6.6, 6.7];
pumpFreqs = 6.4;

powStart = -6.78;
powStep = 0.01;
powStop = -5.44;%0;
pumpPowers = powStart:powStep:powStop;

naPowStart = -13;
naPowStep = 1;
naPowStop = 2;%10;
naPowers = naPowStart:naPowStep:naPowStop;

naStartCenterFreq = 6.4e9;

expSettings = struct(...
    'fluxBiases', fluxBiases,...
    'pumpFreqs', pumpFreqs,...
    'pumpPowers', pumpPowers,...
    'naPowers', naPowers,...
    'naStartCenterFreq', naStartCenterFreq,...
    'naSpan', 0.2e9);

data_path = 'U:\\data\\Berkeley_JBA\\';
cfg_file = 'pumpProbe.json';
fileNumber = 12;
% if ~exist('var', 'fileNumber')
%     fileNumber = 1;
% else
%     fileNumber = fileNumber + 1;
% end

Exp = expManager.pumpProbe(data_path, cfg_file, 'pumpProbe', expSettings, fileNumber);

Exp.Init();
Exp.Do();

delete(Exp); clear Exp