function amp = optimize_amplitude(obj, amp, direction, target)
    % inputs:
    %   amp - initial guess for pulse amplitude
    %   direction - 'X' or 'Y'
    %   target - target angle (e.g. pi/2 or pi)
    %
    % Attempts to optimize the pulse amplitude for a pi/2 or pi pulse about X or Y.

    done = false;
    ct = 1;
    while ~done
        [phase, sigma] = obj.measure_rotation_angle(amp, direction, target);
        ampTarget = target/phase * amp;
        ampError = amp - ampTarget;
        fprintf('Amplitude error: %.4f\n', ampError);

        amp = ampTarget;
        ct = ct + 1;

        % check for stopping condition
        phaseError = phase - target;
        if (abs(phaseError) < 1e-2) || (abs(phaseError/sigma) < 1) || ct > 5
            if abs(phaseError) < 1e-2
                fprintf('Reached target rotation angle accuracy\n');
            elseif abs(phaseError/sigma) < 1
                fprintf('Reached phase uncertainty limit\n');
            else
                warning('Hit max iteration count');
            end
            done = true;
        end
    end
end