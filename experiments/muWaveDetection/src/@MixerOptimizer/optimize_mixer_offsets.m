% Copyright 2010 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% File: optimize_mixer_offsets.m
%
% Author: Blake Johnson, BBN Technologies
%
% Description: Searches for optimal I/Q offset voltages to minimize carrier
% leakage.
%
% Nelder-Mead Simplex implementation adapted from code in Numerical Recipes
% in C.

function [i_offset, q_offset] = optimize_mixer_offsets(obj)
    % unpack constants from cfg file
    ExpParams = obj.inputStructure.ExpParams;
    spec_analyzer_span = ExpParams.SpecAnalyzer.span;
    spec_resolution_bw = ExpParams.SpecAnalyzer.resolution_bw;
    spec_sweep_points = ExpParams.SpecAnalyzer.sweep_points;
    awg_I_channel = ExpParams.Mixer.I_channel;
    awg_Q_channel = ExpParams.Mixer.Q_channel;
    max_offset = ExpParams.Search.max_offset; % max I/Q offset voltage
    max_steps = ExpParams.Search.max_steps;
    min_step_size = ExpParams.Search.min_step_size;
    pthreshold = ExpParams.Search.power_threshold;
    dthreshold = ExpParams.Search.distance_threshold;
    verbose = obj.inputStructure.verbose;
    simulate = obj.inputStructure.SoftwareDevelopmentMode;
    simul_vertex.a = 0;
    simul_vertex.b = 0;
    fevals = 0;
    fevals2 = 0;
    zeroWaveform = APSWaveform();
    zeroWaveform.data = int16(zeros(1,1000));
    
    % initialize instruments
    if ~simulate
        % grab instrument objects
        sa = obj.sa;
        awg = obj.awg;
        
        % center on the current spec generator frequency
        sa.center_frequency = obj.specgen.frequency * 1e9;
        sa.span = spec_analyzer_span;
        sa.sweep_mode = 'single';
        sa.resolution_bw = spec_resolution_bw;
        sa.sweep_points = spec_sweep_points;
        sa.video_averaging = 0;
        sa.sweep();
        sa.peakAmplitude();
        
        awg.operationComplete();
        awg.run();
        awg.waitForAWGtoStartRunning();
    end
    
    % 'global' variables
    vertices = struct();
    values = zeros(1,3);
    high = 1;
    middle = 1;
    low = 1;
    
    % search for best I and Q values to minimize the peak amplitude
    [i_offset, q_offset] = optimize();
    
    % restore spectrum analyzer to a normal state
    if ~simulate
        sa.sweep_mode = 'cont';
        sa.resolution_bw = 'auto';
        sa.sweep_points = 800;
        sa.sweep();
        sa.peakAmplitude();
    end
    
    % local functions
    
    %% Optimizes DAC outputs on channels A and B to minimize the output
     % voltage of the log amp.
     %
     % Uses the Nelder-Mead Simplex method in fminsearch
    %%
    function [i_offset, q_offset] = optimize()

      % initialize vertices and values
      vertices(1).a = 0;
      vertices(1).b = 0;
      vertices(2).a = max_offset/2;
      vertices(2).b = 0;
      vertices(3).a = 0;
      vertices(3).b = max_offset/2;

      for i = 1:3
        setOffsets(vertices(i));
        values(i) = readPower();
      end

      for steps = 1:max_steps
        % determine the order (high, middle, low) of the vertices
        [~, order] = sort(values);
        [low, middle, high] = deal(order(1), order(2), order(3));

        % compute power difference between high and low points
        ptol = abs(values(high) - values(low));
        % distance between high and low vertices;
        dtol = sqrt( (vertices(low).a - vertices(high).a)^2 + (vertices(low).b - vertices(high).b)^2);
        if (verbose)
            fprintf('High: %.2f, Middle: %.2f, Low: %.2f\n', values([high middle low]));
            fprintf('Power difference: %.2f, High-Low distance: %.3f\n', [ptol dtol]);
        end
        if (ptol < pthreshold && dtol < dthreshold)
          setOffsets(vertices(low));
          fprintf('Nelder-Mead optimum: %.2f\n', values(low));
          fprintf('Offset: (%.3f, %.3f)\n', [vertices(low).a vertices(low).b]);
          if verbose, fprintf('Optimization converged in %d steps\n', steps); end
          % turn on video averaging
          sa.number_averages = 10;
          sa.video_averaging = 1;
          % start local search around minimum
          [i_offset, q_offset] = localSearch(vertices(low));
          if (verbose)
              fprintf('Total calls to readPower: %d\n', fevals);
              fprintf('Total calls to setOffsets: %d\n', fevals2);
          end
          return
        end

        % begin iteration. first extrapolate by a factor -1 through the face of the simplex across
        % from the high point, i.e. reflect the simplex from the high point
        trial = extrapolate(-1.0);
        if (trial < values(low))
          % gives a better result than the previous best point, so try an additional extrapolation
          % by a factor 2
          trial = extrapolate(2.0);
        elseif (trial >= values(middle))
          % reflected point is worse than the middle point, so look for an intermediate lower 
          % point, i.e. do a 1D contraction
          save = values(high);
          trial = extrapolate(0.5);
          if (trial >= save)
            % can't seem to get rid of that high point, better contract around the lowest (best) point
            for i = 1:3
              if (i ~= low)
                vertices(i).a = 0.5 * ( vertices(i).a + vertices(low).a);
                vertices(i).b = 0.5 * ( vertices(i).b + vertices(low).b);
                setOffsets(vertices(i));
                values(i) = readPower();
              end
            end
          end
        end
      end

      setOffsets(vertices(low));
      fprintf('Offset: (%.3f, %.3f)\n', [vertices(low).a vertices(low).b]);
      warning('N-M optimization timed out, starting local search.');
      [i_offset, q_offset] = localSearch(vertices(low));     
    end

    function trial = extrapolate(factor)

        % compute average coordinates of low and middle vertices
        a_mean = mean([vertices(low).a vertices(middle).a]);
        b_mean = mean([vertices(low).b vertices(middle).b]);

        new_vertex.a = a_mean * (1.0 - factor) + vertices(high).a * factor;
        new_vertex.b = b_mean * (1.0 - factor) + vertices(high).b * factor;

        % contrain vertex coordinates to be in [-max_offset, max_offset]
        new_vertex.a = constrain(new_vertex.a, -max_offset, max_offset);
        new_vertex.b = constrain(new_vertex.b, -max_offset, max_offset);

        setOffsets(new_vertex);
        trial = readPower();
        if trial < values(high)
            values(high) = trial;
            vertices(high) = new_vertex;
        end
    end

    % search the local 3x3 grid around the best value found by Nelder Mead search
    function [i, q] = localSearch(v_start)
      v = v_start;
      v_best = v_start;
      setOffsets(v_start);
      p_best = readPower();

      for i = (v_start.a-min_step_size):min_step_size:(v_start.a+min_step_size)
          for j = (v_start.b-min_step_size):min_step_size:(v_start.b+min_step_size)
              v.a = i;
              v.b = j;
              setOffsets(v);
              p = readPower();
              if (verbose)
                  fprintf('Offset: (%.3f, %.3f), Power: %.2f\n', [v.a v.b p]);
              end
              if p < p_best
                v_best = v;
                p_best = p;
              end
          end
      end

      setOffsets(v_best);
      i = v_best.a;
      q = v_best.b;
      fprintf('Local search finished with power = %.2f dBm\n', p_best);
      fprintf('Offset: (%.3f, %.3f)\n', [i q]);
    end

    function power = readPower()
        if ~simulate
            power = sa.peakAmplitude();
        else
            best_a = 0.017;
            best_b = -0.005;
            distance = sqrt((simul_vertex.a - best_a)^2 + (simul_vertex.b - best_b)^2);
            power = 20*log10(distance);
        end
        fevals = fevals + 1;
    end

    function setOffsets(vertex)
        if ~simulate
            switch class(awg)
                case 'deviceDrivers.Tek5014'
                    awg.(['chan_' num2str(awg_I_channel)]).offset = vertex.a;
                    awg.(['chan_' num2str(awg_Q_channel)]).offset = vertex.b;
                case 'deviceDrivers.APS'
                    awg.stop();
                    % update I waveform
                    zeroWaveform.set_offset(vertex.a);
                    awg.loadWaveform(awg_I_channel-1, zeroWaveform.prep_vector());
                    % update I zero register
                    offset = vertex.a * 8191;
                    awg.setOffset(awg_I_channel-1, offset);
                    % update Q waveform
                    zeroWaveform.set_offset(vertex.b);
                    awg.loadWaveform(awg_Q_channel-1, zeroWaveform.prep_vector());
                    % update Q zero register
                    offset = vertex.b * 8191;
                    awg.setOffset(awg_Q_channel-1, offset);
                    awg.run();
            end
            pause(0.02);
            sa.sweep();
        else
            simul_vertex.a = vertex.a;
            simul_vertex.b = vertex.b;
        end
        fevals2 = fevals2 + 1;
    end

end

function out = constrain(value, min, max)
    if value < min
        out = min;
    
    elseif value > max
        out = max;
    else
        out = value;
    end
end