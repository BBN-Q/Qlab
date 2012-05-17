function out = analyzeRBoverlaps
    % user selects a set of files
    [filenames, pathname] = uigetfile('*.out', 'MultiSelect', 'on');
    if isequal(filenames,0) || isequal(pathname,0)
        fprintf('No files selected\n');
        return
    end
    
    filenames = sort(filenames);
    
    % load the data
    data = cell(1,length(filenames));
    for ct = 1:length(filenames)
        fullpath = [pathname '/' filenames{ct}];
        tmp = loadData(false, fullpath);
        tmpdata = tmp.abs_Data; % choose amplitude or phase here
        
        % extract calibration experiments
        nbrRepeats = 2;
        zeroCal = mean(tmpdata(end-2*nbrRepeats+1:end-nbrRepeats));
        piCal = mean(tmpdata(end-nbrRepeats+1:end));
        scaleFactor = (piCal - zeroCal)/2;

        % rescale
        data{ct} = (tmpdata(1:end-2*nbrRepeats) - zeroCal)./scaleFactor - 1;
    end
    
    % extract the gate errors for each choice of recovery gate
    avgFidelities = zeros(1,8);
    processFidelities = zeros(1,8);
    seqlengths = [2, 4, 8, 12, 16, 24, 32, 48, 64, 80, 96];
    % fit to exponential, forcing the amplitude to be 1 and midpoint to
    % be 0.5
    fitf = @(p,n) (0.5*p.^n + 0.5);
    h = figure();
    
    for ct = 1:length(filenames)
        avgFidelity = 0.5 * (1 - mean(reshape(data{ct}, 32, 11)));
        errors = 0.5 * std(reshape(data{ct}, 32, 11))/sqrt(32);
        
        if avgFidelity(1) > 0.8
            pGuess = 0.99;
        else
            pGuess = 0.55;
        end
        [beta, r, j] = nlinfit(seqlengths, avgFidelity, fitf, pGuess);
        avgFidelities(ct) = beta(1) + (1-beta(1))/2;
        processFidelities(ct) = beta(1) + (1-beta(1))/2^2;
        
        plot(seqlengths, avgFidelity, '.', 'Color', [.5 .5 .5])
        hold on
        errorbar(seqlengths, avgFidelity, errors, '.')
        yfit = fitf(beta, 1:seqlengths(end));
        plot(1:seqlengths(end), yfit, 'r')
        pause(0.1)
    end
    out = processFidelities;
end