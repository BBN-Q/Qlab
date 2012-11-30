classdef Pulse < handle
   % PULSE - a utility class of PatternGen
   %  Calls to pg.pulse return Pulse objects. Mainly do this for the
   %  pretty-printing of cell arrays of Pulses
   
   properties (Constant = true)
      identityPulses = {'QId' 'MId' 'ZId'};
   end
   
   properties
       label
       pulseArray = {}; % pulse shapes after frame selection
       pulsePtrs = []; % index into hashKeys
       hashKeys = [];
       frameChanges = [];
       T % mixer correction matrix

       isTimeAmplitude = 0;
       isZero = 0;
   end
   
   methods
       %constructor
       function obj = Pulse(label, params, linkListMode)
           %Pulse(label, params, linkListMode)
           %  label - The name of the pulse
           %  params - pulse parameters
           %  linkListMode - controls whether final pulses are computed now
           obj.label = label;
           
           % precompute the pulses
           % start by find longest parameter vector
           nbrPulses = max(structfun(@Pulse.getlength, params));
           %obj.pulseShapes = cell(nbrPulses,1);
           %obj.angles = zeros(nbrPulses, 1);
           %obj.modAngles = cell(nbrPulses,1);
           %obj.frameChanges = zeros(nbrPulses,1);
           obj.pulseArray = cell(nbrPulses,1);
           obj.hashKeys = cell(nbrPulses,1);
           obj.pulsePtrs = zeros(nbrPulses,1);
           obj.frameChanges = zeros(nbrPulses,1);
           % pull out the pulse function handle and T matrix
           if ismethod(obj, params.pType)
               pf = eval(['@obj.' params.pType]);
           else
               error('Unknown pulse function %s', params.pType);
           end
           obj.T = params.T;
           params = rmfield(params, 'T'); % getelement does not work on matrix elements
           
           % construct cell array of pulses for all parameter vectors
           idx = 1;
           for n = 1:nbrPulses
               % pick out the nth element of parameters provided as
               % vectors
               elementParams = structfun(@(x) Pulse.getelement(x, n), params, 'UniformOutput', 0);

               % It seems we shoud be able to do this with nargout but all
               % the pulse functions have vargout i.e. return -1 for
               % nargout
               % Try for the frame change version
               try
                   [xpulse, ypulse, obj.frameChanges(n)] = pf(elementParams);
               catch exception
                   %If we don't have enough output arguments try for the
                   %non frame-change version
                   if strcmp(exception.identifier,'MATLAB:maxlhs')
                       [xpulse, ypulse] = pf(elementParams);
                       obj.frameChanges(n) = 0;
                   else
                       rethrow(exception);
                   end
               end
               
               % add buffer padding
               duration = elementParams.duration;
               width = elementParams.width;
               if (duration > width)
                   padleft = floor((duration - width)/2);
                   padright = ceil((duration - width)/2);
                   xpulse = [zeros(padleft,1); xpulse; zeros(padright,1)];
                   ypulse = [zeros(padleft,1); ypulse; zeros(padright,1)];
               end
               
               % lab frame pulse
               pulseShape = xpulse +1j*ypulse;
               
               % precompute SSB modulation angles
               timeStep = 1/params.samplingRate;
               modAngles = - 2*pi*params.modFrequency*timeStep*(0:(length(pulseShape)-1))';
               
               % the pulse in the rotated frame
               [xpulse, ypulse] = obj.frameChange(pulseShape, modAngles, elementParams.angle);
               
               % square pulses and identity pulses are special
               if strcmp(params.pType, 'square')
                    obj.isTimeAmplitude = 1;
                    %Only keep one representative (x,y) point
                    xpulse = xpulse(fix(end/2));
                    ypulse = ypulse(fix(end/2));
                end
                if ismember(label, obj.identityPulses)
                    obj.isZero = 1;
                end
               
               % check to see if we already have this pulse
               hash = Pulse.hash([xpulse, ypulse]);
               if ~any(obj.hashKeys == hash)
                   obj.pulseArray{idx} = [xpulse, ypulse];
                   obj.hashKeys{idx} = hash;
                   obj.pulsePtrs(n) = idx;
                   idx = idx + 1;
               else
                   obj.pulsePtrs(n) = find(obj.hashKeys, hash, 'first');
               end
           end
       end
       
       function [xpulse, ypulse] = frameChange(obj, complexPulse, modAngles, angle)
           % rotate a pulse into a frame determined by modAngles (length n
           % vector of instantaneous frames) and angle (global frame)
           tmpAngles = angle + modAngles;
           complexPulse = complexPulse.*exp(1j*tmpAngles);
           xpulse = real(complexPulse);
           ypulse = imag(complexPulse);
       end
       
       % pretty printer
       function disp(obj)
           disp(obj.label);
       end
       
       function out = print(obj)
           out = obj.label;
       end
   end
   
   methods (Static)
       % forward references to pulses defined in separate files
       % basic shapes
       [outx, outy] = square(params);
       [outx, outy] = gaussian(params);
       [outx, outy] = gaussOn(params);
       [outx, outy] = gaussOff(params);
       [outx, outy] = tanh(params);
       % derivatives
       [outx, outy] = derivGaussian(params);
       [outx, outy] = derivGaussOn(params);
       [outx, outy] = derivGaussOff(params);
       [outx, outy] = derivGaussSquare(params)
       % DRAG pulses
       [outx, outy] = drag(params);
       [outx, outy] = dragGaussOn(params);
       [outx, outy] = dragGaussOff(params);
       % composites
       [outx, outy] = gaussSquare(params);
       [outx, outy] = dragSquare(params);
       % more complex shapes
       [outx, outy] = hermite(params);
       [outx, outy, frameChange] = arbAxisDRAG(params);
       [outx, outy] = arbitrary(params);
       

       function h = hash(array)
           persistent sha
           if isempty(sha)
               sha = java.security.MessageDigest.getInstance('SHA-1');
           end
           % uses java object to build hash string.
           if isempty(array)
               array = 0;
           end
           sha.reset();
           %Salt the array to avoid collisions
           sha.update([array(:); array(:)+10101]);
           h = sha.digest();
           % convert to hex string
           h = sprintf('%02x',uint8(h));
           % turn numbers into uppercase letters
           h(h < 'A') = h(h < 'A') + 17;
       end
       
       % helper methods
       function out = getelement(x, n)
           % if x is a list, return the nth element, otherwise return x
           if isscalar(x) || ischar(x)
               out = x;
           else
               out = x(n);
           end
       end
       
       function out = getlength(x)
           % get the length of a parameter list
           if isscalar(x) || ischar(x)
               out = 1;
           else
               out = length(x);
           end
       end
   end
end