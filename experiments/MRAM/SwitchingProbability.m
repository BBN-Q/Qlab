%% Measure switching probability vs pulse duration/amplitude

%% Instrument setup
bop = deviceDrivers.KepcoBOP();
bop.connect(1);
bop.mode = 'current';
bop.limit = 'MAX';
bop.output = true;

srs = deviceDrivers.SRS830();
srs.connect(8);

ppl = deviceDrivers.Picosec10070A();
ppl.connect(5);

%% Constants

%Threshold distinguishing P from AP
threshold = -18e-6;

%Low and high values for the reset and set point (in current units)
H_ResetLow = 20;
H_ResetHigh = -5;
H_SetPoint = 8;


%% Sweeps 

%Pulse amplitude to loop over
%pulseAmps = [linspace(-4,-1,40), -0.5, 0, 0.5, linspace(1, 4, 40)];
pulseAmps = [1.8, 2.1, 2.4];
%Pulse lengths to loop over
pulseLengths = 1e-12*linspace(100,1500,90);

%% pulse length

allTransitionMats = cell(length(pulseLengths),1);
multiWaitbar('Pulse Length', 0, 'Color', 'b');
for lengthct = 1:length(pulseLengths)
    ppl.duration = pulseLengths(lengthct);
    allTransitionMats{lengthct} = switching_prob_field_reset(bop, ppl, srs, H_ResetLow, H_ResetHigh, H_SetPoint, threshold);
    multiWaitbar('Pulse Length', lengthct/length(pulseLengths));
end
ramp(bop, 0, 10);
multiWaitbar('CLOSEALL');

%% pulse amp

allTransitionMats = cell(length(pulseAmps),1);
multiWaitbar('Pulse Amp.', 0, 'Color', 'r');
for ampct = 1:length(pulseAmps)
    ppl.amplitude = pulseAmps(ampct);
    allTransitionMats{ampct} = switching_prob_field_reset(bop, ppl, srs, H_ResetLow, H_ResetHigh, H_SetPoint, threshold);
    multiWaitbar('Pulse Amp.', ampct/length(pulseAmps));
end
ramp(bop, 0, 10);
multiWaitbar('CLOSEALL');

%% pulse amp ; pulse length 

allTransitionMats = cell(length(pulseAmps),1);
multiWaitbar('Pulse Amp.', 0, 'Color', 'b');
multiWaitbar('Pulse Length', 0, 'Color', 'r');

for ampct = 1:length(pulseAmps) 
    ppl.amplitude = pulseAmps(ampct);
    allTransitionMats{ampct} = cell(length(pulseLengths),1);
    
    multiWaitbar('Pulse Length', 'Reset');
    for lengthct = 1:length(pulseLengths)
        ppl.duration = pulseLengths(lengthct);
        allTransitionMats{ampct}{lengthct} = switching_prob_field_reset(bop, ppl, srs, H_ResetLow, H_ResetHigh, H_SetPoint, threshold);
        multiWaitbar('Pulse Length', lengthct/length(pulseLengths));
    end
    multiWaitbar('Pulse Amp.', ampct/length(pulseAmps));
end
ramp(bop, 0, 10);
multiWaitbar('CLOSEALL');


%% Plotting transition matrices

%First the transition matrices themselves to get a better feel for the
%numbers

figure('OuterPosition', [0, 1, 2500, 800])
for ct = 1:length(transitionMats)
    subplot(2,10,ct)
    imagesc(transitionMats{ct}, [0,120]);
    colormap(flipud(gray));
    textStrs = cellstr(int2str(transitionMats{ct}(:)));
    [x,y] = meshgrid(1:2);
    strsHandles = text(x(:), y(:), textStrs(:), 'HorizontalAlignment','center');
    textColours = repmat(transitionMats{ct}(:) > 60, 1, 3);
    set(strsHandles, {'Color'}, num2cell(textColours,2));
    set(gca(), 'XTick', 1:2, 'XTickLabel', {'P', 'AP'}, 'YTick', 1:2, 'YTickLabel', {'P', 'AP'});
end

tightfig;
    

%% Plotting switching probabilities as a function of pulse amp and width

figure()

for ct = 1:6
    axesH = subplot(2,3,ct);
    plot_switching_probs(allTransitionMats{ct}, axesH, 1e9*pulseLengths);
    xlabel('Pulse Length. (ns)');
    xlim([pulseLengths(1)*1e9, pulseLengths(end)*1e9]);
    title(sprintf('Pulse Amp = %.2f', pulseAmps(ct)));
end
