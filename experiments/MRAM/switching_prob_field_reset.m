function [transitionMat, meanP, meanAP] = switching_prob_field_reset(bop, ppl, srs, H_ResetLow, H_ResetHigh, H_SetPoint, threshold)

%Plan is to measure the transition matrix at each pulse level by repeatedly
%pulsing. Andy and Li suggested reseting the device with field every N
%tries. To sample fairly from both P->AP and AP->P we should probably
%alternate which side we reset from 

transitionMat = zeros(2);
numResets = 100; %should be even
multiWaitbar('Reset Loop', 'Reset');
multiWaitbar('Reset Loop', 'Color', 'g');

Ps = zeros(numResets/2, 1);
APs = zeros(numResets/2, 1);

for resetct = 1:numResets
    %Use the field to reset 
    if mod(resetct,2) == 0
        ramp(bop, H_ResetLow, 4);
        ramp(bop, H_SetPoint, 4);
        pause(.1); curVal = srs.R;
        Ps(resetct/2) = curVal;
%             assert(curVal<threshold, 'Oops! did not reset with field to P state');
        prevState = 'P';
        if(curVal > threshold)
            warning('Oops! did not reset with field to P state');
            prevState = 'AP';
        end
    else
        ramp(bop, H_ResetHigh, 4);
        ramp(bop, H_SetPoint, 4);
        pause(.1); curVal = srs.R;
        APs(floor(resetct/2)+1) = curVal;
%             assert(curVal>threshold, 'Oops! did not reset with field to AP state');
        prevState = 'AP';
        if(curVal < threshold)
            warning('Oops! did not reset with field to AP state');
            prevState = 'P';
        end
    end

    %Send pulses and see if it flips
    for pulsect = 1:4
        %Turn the lock-in way down
        srs.sineAmp = 0.004; pause(0.2);
        ppl.trigger();
        srs.sineAmp = 2;
        pause(.4); curVal = srs.R;
        if curVal < threshold
            curState = 'P';
        else 
            curState = 'AP';
        end

        switch [prevState '->' curState]
            case 'P->P'
                transitionMat(1,1) = transitionMat(1,1) + 1;
            case 'P->AP'
                transitionMat(2,1) = transitionMat(2,1) + 1;
            case 'AP->AP'
                transitionMat(2,2) = transitionMat(2,2) + 1;
            case 'AP->P'
                transitionMat(1,2) = transitionMat(1,2) + 1;
        end
        prevState = curState;
    end
    multiWaitbar('Reset Loop', resetct/numResets);
end   

meanP = mean(Ps);
meanAP = mean(APs);

