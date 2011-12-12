function [errorMsg] = pulseCalibrationDo(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE: [errorMsg] = pulseCalibrationDo(obj)
%
% Does the following:
% - zeroes the detuning by measuring it with a Ramsey experiment
% - calibrates Pi pulses
% - calibrations Pi/2 pulses
% - calibrates DRAG parameter
%
% v1.0 Aug 24, 2011 Blake Johnson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ExpParams = obj.inputStructure.ExpParams;
QubitSpec = obj.Instr.(ExpParams.QubitSpec);
Loop = obj.populateLoopStructure;

fprintf('\n******BEGINNING OF EXPERIMENT*****\n\n')

    
%% Ramsey
if ExpParams.DoRamsey
    % generate Ramsey sequence
    filename = RamseySequence();
    obj.loadSequence(filename);

    % measure
    obj.homodyneDetection2DDo();

    % analyze
    detuning = obj.analyzeRamsey();

    % adjust drive frequency
    freq = QubitSpec.frequency + detuning;
    QubitSpec.frequency = freq;
end

%% Pi Calibration
if ExpParams.DoPiCal
    for loop_index = 1:Loop.PiCal.steps
        % generate Pi calibration sequence
        filename = PiCalSequence();
        obj.loadSequence(filename);

        % measure
        obj.homodyneDetection2DDo();
    end
    % analyze
    piAmp = obj.analyzePiCal();
    save(obj.pulseParamPath, 'piAmp', '-append', '-v7.3');
end

%% Pi/2 Calibration
if ExpParams.DoPi2Cal
    for loop_index = 1:Loop.Pi2Cal.steps
        % generate Pi/2 calibration sequence
        filename = Pi2CalSequence();
        obj.loadSequence(filename);

        % measure
        obj.homodyneDetection2DDo();
    end
    % analyze
    pi2Amp = obj.analyzePi2Cal();
    save(obj.pulseParamPath, 'pi2Amp', '-append', '-v7.3');
end

%% DRAG calibration    
if ExpParams.DoDRAGCal
    for loop_index = 1:Loop.DRAGCal.steps
        % generate DRAG calibration sequence
        filename = DRAGSequence();
        obj.loadSequence(filename);

        % measure
        obj.homodyneDetection2DDo();
    end
    % analyze
    delta = obj.analyzeDRAG();
    save(obj.pulseParamPath, 'delta', '-append', '-v7.3');
end

fprintf('\n******END OF EXPERIMENT*****\n\n')

end

