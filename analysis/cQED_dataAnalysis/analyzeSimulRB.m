function analyzeSimulRB(data1, data2)

    nbrRandomizations = 32;
    nbrSets = 2;
%     seqlengths = [2, 4, 8, 12, 16, 24, 32, 48, 64, 80, 96];
    seqlengths = [2, 4, 8, 16, 32, 64, 96, 128, 192, 256, 320];
    nbrExps = length(seqlengths)*nbrRandomizations/nbrSets;
    xpts = seqlengths(1 + floor((0:nbrExps-1).*nbrSets./nbrRandomizations));
    
    for ii = 1:nbrSets
        setData = eval(['data' num2str(ii)]);
        raw00 = setData.abs_Data(1:nbrExps);
        raw10 = setData.abs_Data(nbrExps+1:2*nbrExps);
        raw01 = setData.abs_Data(2*nbrExps+1:3*nbrExps);
        raw11 = setData.abs_Data(3*nbrExps+1:4*nbrExps);

        calOffset = 4*nbrExps;
        V00 = mean(setData.abs_Data(calOffset+1:calOffset+2));
        V10 = mean(setData.abs_Data(calOffset+3:calOffset+4));
        V01 = mean(setData.abs_Data(calOffset+5:calOffset+6));
        V11 = mean(setData.abs_Data(calOffset+7:calOffset+8));

        P2Vmap = [V00 V01 V10 V11; ...
                  V10 V11 V00 V01; ...
                  V01 V00 V11 V10; ...
                  V11 V10 V01 V00];

        populations{ii} = P2Vmap\[raw00, raw10, raw01, raw11]';
    end
    
    populations = [populations{:}];
    xpts = repmat(xpts, 1, nbrSets);
    
    %avgPopulations = mean(populations, 2);
    reshapedPops = reshape(populations, 4, nbrRandomizations/nbrSets, length(seqlengths), nbrSets);
    reshapedPops = permute(reshapedPops, [1, 3, 2, 4]);
    reshapedPops = cat(3, reshapedPops(:,:,:,1), reshapedPops(:,:,:,2));
    meanPops = mean(reshapedPops, 3);
    meanStdErrors = std(reshapedPops, 0, 3)/sqrt(nbrRandomizations);
    
    figure
    plot(xpts, populations, '.', 'Color', [.5 .5 .5]);
    hold on
    h(1) = errorbar(seqlengths, meanPops(1,:), meanStdErrors(1,:), '.');
    h(2) = errorbar(seqlengths, meanPops(2,:), meanStdErrors(2,:), 'r.');
    h(3) = errorbar(seqlengths, meanPops(3,:), meanStdErrors(3,:), 'g.');
    h(4) = errorbar(seqlengths, meanPops(4,:), meanStdErrors(4,:), 'k.');
    hold off
    xlabel('Number of Clifford gates')
    ylabel('Population')
    legend(h, {'00', '01', '10', '11'})
    
    fitSeqFidCross(seqlengths, meanPops', true)
    
    % save data to file
    [~, filename, ~] = fileparts(data1.filename);
    filename = [filename '_populations.mat'];
    save(filename, 'seqlengths', 'meanPops', 'meanStdErrors', 'xpts', 'populations');
end