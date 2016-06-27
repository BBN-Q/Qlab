function gateSet = tomo_gate_set(nbrQubits, nbrPulses, varargin)
%tomo_gate_set Returns a set of state preparation or readout unitary gates.
% 
% tomo_gate_set(nbrQubits, nbrPulses)
 
%Basic Pauli operators
X = [0,1; 1,0];
Y = [0,-1i; 1i,0];
Z = [1 0; 0 -1];
I = eye(2);

p = inputParser;
addParameter(p, 'type', 'Clifford', @ischar) %prepared states/meas. axes
addParameter(p, 'prep_meas', 1, @isnumeric) %1 for prep., 2 for meas. pulses
parse(p, varargin{:});
type = p.Results.type;
prep_meas = p.Results.prep_meas;

switch nbrPulses
    case 4
        %Four pulse set
        switch type
            case 'Clifford'
                Uset1Q{1}=eye(2);
                Uset1Q{2}=expm(-1i*(pi/4)*X);
                Uset1Q{3}=expm(-1i*(pi/4)*Y);
                Uset1Q{4}=expm(-1i*(pi/2)*X);
            case 'Tetra'
                if prep_meas==1
                    Uset1Q{1}=eye(2);
                    Uset1Q{2}=expm(-1i*acos(-1/3)*X);
                    Uset1Q{3}=expm(-1i*2*pi/3*Z)*expm(-1i*acos(-1/3)*X);
                    Uset1Q{4}=expm(1i*2*pi/3*Z)*expm(-1i*acos(-1/3)*X);
                else
                    Uset1Q{1}=eye(2);
                    Uset1Q{2}=expm(1i*acos(-1/3)*X);
                    Uset1Q{3}=expm(1i*acos(-1/3)*X)*expm(1i*2*pi/3*Z);
                    Uset1Q{4}=expm(1i*acos(-1/3)*X)*expm(-1i*2*pi/3*Z);
                end
            otherwise
                error('Invalid prep./meas. pulse type')
        end
    case 6
        %Six pulse set
        Uset1Q{1}=eye(2);
        Uset1Q{2}=expm(-1i*(pi/4)*X);
        Uset1Q{3}=expm(1i*(pi/4)*X);
        Uset1Q{4}=expm(-1i*(pi/4)*Y);
        Uset1Q{5}=expm(1i*(pi/4)*Y);
        Uset1Q{6}=expm(-1i*(pi/2)*X);
    case 12
        %12 pulse set
        Uset1Q{1} = I;
        Uset1Q{2} = expm(-1i*(pi/2)*X);
        Uset1Q{3} = expm(-1i*(pi/2)*Y);
        Uset1Q{4} = expm(-1i*(pi/2)*Z);
        Uset1Q{5} = expm(-1i*(pi/3)*(1/sqrt(3))*(X+Y-Z));  %X+Y-Z 120
        Uset1Q{6} = expm(-1i*(pi/3)*(1/sqrt(3))*(X-Y+Z));  %X-Y+Z 120
        Uset1Q{7} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X+Y+Z));  %-X+Y+Z 120
        Uset1Q{8} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X-Y-Z));  %X+Y+Z -120 (equivalent to -X-Y-Z 120)
        Uset1Q{9} = expm(-1i*(pi/3)*(1/sqrt(3))*(X+Y+Z));  %X+Y+Z 120
        Uset1Q{10} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X+Y-Z));  %X-Y+Z -120 (equivalent to -X+Y-Z 120)
        Uset1Q{11} = expm(-1i*(pi/3)*(1/sqrt(3))*(X-Y-Z));  %-X+Y+Z -120 (equivalent to X-Y-Z 120
        Uset1Q{12} = expm(-1i*(pi/3)*(1/sqrt(3))*(-X-Y+Z));  %%X+Y-Z -120 (equivalent to -X-Y+Z 120
    otherwise
        error('Unable to handle number of pulses %d', nbrPulses);
end

%Now kron things together 
%First create a matrix with giving the mod nbrPulses description of which 1Q gates to kron together
numGates = nbrPulses^nbrQubits;
kronMat = zeros([numGates, nbrQubits], 'uint8');
for qubitct = 1:nbrQubits
    kronMat(:,qubitct) = reshape(repmat(1:nbrPulses, nbrPulses^(nbrQubits-qubitct), nbrPulses^(qubitct-1)), numGates, 1);
end

gateSet = cell(numGates,1);
for gatect = 1:numGates
    gateSet{gatect} = 1;
    for qubitct = 1:nbrQubits
        gateSet{gatect} = kron(gateSet{gatect}, Uset1Q{kronMat(gatect, qubitct)});
    end
end


