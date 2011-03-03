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
% Description: Searches for optimal I/Q offset voltages to minimize carrier
% leakage.

function optimize_mixer_offsets2()
    % load constants here (TO DO: load from cfg file)
    spec_analyzer_address = 17;
    spec_generator_address = 19;
    awg_address = 2;
    spec_analyzer_span = 1e6; % 1 MHz span
    awg_I_channel = 3;
    awg_Q_channel = 4;
    max_offset = 0.05; % 50 mV max I/Q offset voltage
    max_steps = 50;
    min_step_size = 0.001;
    pthreshold = 2.0;
    dthreshold = 0.001;
    verbose = true;
    simulate = false;
    simul_vertex.a = 0;
    simul_vertex.b = 0;
    
    % initialize instruments
    if ~simulate
        specgen = deviceDrivers.AgilentN5183A();
        specgen.connect(spec_generator_address);

        sa = deviceDrivers.HP71000();
        sa.connect(spec_analyzer_address);
        sa.center_frequency = specgen.frequency * 1e9;
        sa.span = spec_analyzer_span;
        sa.sweep();
        sa.peakAmplitude();

        awg = deviceDrivers.Tek5014();
        awg.connect(awg_address);
    end
    
    % search for best I and Q values to minimize the peak amplitude
    optimize();
    
    % local functions
    
    %% Optimizes DAC outputs on channels A and B to minimize the output
     % voltage of the log amp.
     %
     % Uses a Nelder Mead method.
    %%
    function optimize()
        % initial search point
        x0 = [max_offset/2; max_offset/2];

        [x, fval, ~, output] = fminsearch(@objective_fcn, x0, ...
            optimset('MaxIter', max_steps, 'TolFun', pthreshold, 'TolX', dthreshold));
        
        fprintf('Nelder-Mead optimum: %.2f\n', fval);
        fprintf('Offset: (%.3f, %.3f)\n', x);
        fprintf('Optimization converged in %d steps\n', output.iterations);
        % perform local search around minimum
        fprintf('Starting local search\n');
        localSearch(struct('a', x(1), 'b', x(2)));
    end

    % search the local 3x3 grid around the best value found by Nelder Mead search
    function localSearch(v_start)
      v = v_start;
      v_best = v_start;
      setOffsets(v_start);
      p_best = readPower();

      for i = (v_start.a-min_step_size):min_step_size:(v_start.a+min_step_size)
          for j = (v_start.b-min_step_size):min_step_size:(v_start.b+min_step_size)
              v.a = i;
              v.b = j;
              setOffsets(v);
              if (verbose)
                  fprintf('Offset: (%.3f, %.3f)\n', [v.a v.b]);
              end
              p = readPower();
              if p < p_best
                v_best = v;
                p_best = p;
              end
          end
      end

      setOffsets(v_best);
      fprintf('Local search finished with power = %.2f dBm\n', p_best);
      fprintf('Offset: (%.3f, %.3f)\n', [v_best.a v_best.b]);
    end

    function out = objective_fcn(x)
        setOffsets(struct('a', x(1), 'b', x(2)));
        out = readPower();
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
    end

    function setOffsets(vertex)
        if ~simulate
            awg.(['chan_' num2str(awg_I_channel)]).offset = vertex.a;
            awg.(['chan_' num2str(awg_Q_channel)]).offset = vertex.b;
            pause(0.05);
            sa.sweep();
        else
            simul_vertex.a = vertex.a;
            simul_vertex.b = vertex.b;
        end
    end

end