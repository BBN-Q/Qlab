function [success] = waitForAWGtoStartRunning(obj,maxTime,maxTrys)

AWG = obj;

if ~exist('maxTime','var')
    maxTime = 15; %seconds
end

if ~exist('maxTrys','var')
    maxTrys = 3; %seconds
end

numTrys = 0;
while 1
    numTrys = numTrys+1;
    t_start = clock;
    while 1
        fprintf('waiting for AWG\n')
        OperationState = AWG.OperationState;
        if  OperationState > 0
            success = 1;
            fprintf('AWG is ready\n')
            break
        elseif etime(clock,t_start) > maxTime
            success = 0;
            break
        end
        pause(0.1)
    end
    if success == 1
        break
    elseif numTrys > maxTrys
        success = 0;
        break
    end
end

end