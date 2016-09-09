fluxStart = 0.0;
fluxStep = 0.4;%changed 121005 HP
fluxStop = 2;%4.0;
fluxBiases = fluxStart:fluxStep:fluxStop;

pumpStart = 6.4;
pumpStep = 0.1;
pumpStop = 6.6;%7.5;
pumpFreqs = pumpStart:pumpStep:pumpStop;

powStart = -10;
powStep = 1;
powStop = -8;%0;
pumpPowers = powStart:powStep:powStop;

naPowStart = -13;
naPowStep = 1;
naPowStop = 10;%10;
naPowers = naPowStart:naPowStep:naPowStop;

naStartCenterFreq = 6.9e9;

expSettings = struct(...
    'fluxBiases', fluxBiases,...
    'pumpFreqs', pumpFreqs,...
    'pumpPowers', pumpPowers,...
    'naPowers', naPowers,...
    'naStartCenterFreq', naStartCenterFreq);

data_path = 'U:\\data\\Berkeley_JBA\\';
cfg_file = 'pumpProbe.json';
fileNumber = 1;
% if ~exist('var', 'fileNumber')
%     fileNumber = 1;
% else
%     fileNumber = fileNumber + 1;
% end

Exp = expManager.pumpProbe(data_path, cfg_file, 'pumpProbe', expSettings, fileNumber);

Exp.Init();
Exp.Do();

delete(Exp); clear Exp