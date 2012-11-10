classdef Pulse < handle
   % PULSE - a utility class of PatternGen
   %  Calls to pg.pulse return Pulse objects. Mainly do this for the
   %  pretty-printing of cell arrays of Pulses
   
   properties (Constant = true)
      identityPulses = {'QId' 'MId' 'ZId'};
   end
   
   properties
       label
       pulseShapes = {}; % pre-computed complex pulse shapes
       pulseArray = {}; % pulse shapes after frame selection
       angles % rotation axis for each pulse
       modAngles
       frameChanges
       T % mixer correction matrix
       
       % for link list mode
       hashKeys = [];
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
           obj.pulseShapes = cell(nbrPulses,1);
           obj.angles = zeros(nbrPulses, 1);
           obj.modAngles = cell(nbrPulses,1);
           obj.frameChanges = zeros(nbrPulses,1);
           % pull out the pulse function handle and T matrix
           pf = params.pf;
           obj.T = params.T;
           
           % construct cell array of pulses for all parameter vectors
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
               
               % store the pulse
               obj.pulseShapes{n} = xpulse +1j*ypulse;
               
               % precompute SSB modulation angles
               timeStep = 1/params.samplingRate;
               obj.modAngles{n} = - 2*pi*params.modFrequency*timeStep*(0:(length(obj.pulseShapes{n})-1))';
           end
           
           if linkListMode           
               % how this should look
                %retVal.pulseArray = arrayfun(@pulseFunction, 1:nbrPulses, 'UniformOutput', 0);
                %retVal.hashKeys = cellfun(@obj.hashArray, retVal.pulseArray, 'UniformOutput', 0);
                % some weird MATLAB bug causes this not to work, hence the
                % following for loop
                obj.pulseArray = cell(nbrPulses,1);
                obj.hashKeys = cell(nbrPulses,1);
                for ii = 1:nbrPulses
                    [xpulse, ypulse] = obj.getPulse(ii, 0);
                    obj.pulseArray{ii} = [xpulse, ypulse];
                    obj.hashKeys{ii} = Pulse.hash(obj.pulseArray{ii});
                end
                if strcmp(params.pType, 'square')
                    %Square pulses are time/amplitude pairs
                    obj.isTimeAmplitude = 1;
                    %We only want to hash the first point as only the
                    %amplitude matters. 
                    obj.hashKeys{ii} = Pulse.hash(obj.pulseArray{ii}(fix(end/2),:));
                end
                if ismember(label, obj.identityPulses)
                    obj.isZero = 1;
                end
           end
       end
       
       function [xpulse, ypulse, frameChange] = getPulse(obj, n, accumulatedPhase)
           % n - index into parameter arrays
           % accumulatedPhase - allows dynamic updating of the basis
           %   based upon the position in time of the pulse
           angle = obj.angles(1+mod(n-1, length(obj.angles)));
           complexPulse = obj.pulseShapes{1+mod(n-1, length(obj.pulseShapes))};
           
           % rotate and correct the pulse
           tmpAngles = angle + accumulatedPhase + obj.modAngles{1+mod(n-1, length(obj.modAngles))};
           complexPulse = complexPulse.*exp(1j*tmpAngles);
           xypairs = obj.T*[real(complexPulse) imag(complexPulse)].';
           xpulse = xypairs(1,:).';
           ypulse = xypairs(2,:).';
           
           frameChange = obj.frameChanges(1+mod(n-1, length(obj.frameChanges)));
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