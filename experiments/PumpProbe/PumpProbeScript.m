fluxStart = 0.0;
fluxStep = 0.1;
fluxStop = 0.2;%4.0;
fluxBiases = fluxStart:fluxStep:fluxStop;

pumpStart = 6.4;
pumpStep = 0.1;
pumpStop = 6.6;%7.5;
pumpFreqs = pumpStart:pumpStep:pumpStop;

powStart = -10;
powStep = 1;
powStop = -8;%0;
pumpPowers = powStart:powStep:powStop;

naPowStart = -27;
naPowStep = 1;
naPowStop = -25;%10;
naPowers = naPowStart:naPowStep:naPowStop;

naStartCenterFreq = 6.5e9;

expSettings = struct(...
    'fluxBiases', fluxBiases,...
    'pumpFreqs', pumpFreqs,...
    'pumpPowers', pumpPowers,...
    'naPowers', naPowers,...
    'naStartCenterFreq', naStartCenterFreq);

data_path = 'U:\\data\\Berkeley_JBA\\';
cfg_file = 'pumpProbe.json';
if ~exist('var', 'fileNumber')
    fileNumber = 1;
else
    fileNumber = fileNumber + 1;
end

Exp = expManager.pumpProbe(data_path, cfg_file, 'pumpProbe', expSettings, fileNumber);

Exp.Init();
Exp.Do();

delete(Exp); clear Exp