function out = pauli_twirl_tomo(expResults, Utilts)
% Optimize Pauli Twirl Tomography
%Assume we measure decay rate of X,Y,Z input states for each experiment
%Take-in:
%  1. measured decay rates: expResults (3 X number of Frames)
%  2. Tranformation to each tilted Pauli frame: Utilts (cell array of matrices)
%      Utilt transforms original basis to tilted basis 

numTilts = length(Utilts);
assert(size(expResults,2) == numTilts)

%Plan:
%Optimize chi matrix

% Default to quiet
if ~exist('verbose', 'var')
    verbose = 0;
end

%Chi matrix in Pauli basis (I, X, Y, Z)
chiSDP = sdpvar(4, 4, 'hermitian', 'complex');

pauliOps = cell(4,1);
pauliOps{1} = eye(2);
pauliOps{2} = [0, 1;1, 0];
pauliOps{3} = [0, -1i;1i, 0];
pauliOps{4} = [1, 0;0, -1];


% Now each measurement result corresponds a diagonal element of the chi matrix in some basis
% We need to transform back to original Pauli basis and write out
% constraints
predictedResults = sdpvar(3, numTilts, 'full', 'real');

for tiltct = 1:numTilts
    for prepct = 1:3
        %X input tell's us coefficient of Chi_{xx} which Chi(2,2)
        %Write out X in tilted basis back to X in original basis
        tiltedVec = Utilts{tiltct}*pauliOps{prepct+1}*Utilts{tiltct}';
        tmpDecomp = pauli_decompose(tiltedVec);
        predictedResults(prepct,tiltct) = tmpDecomp'*chiSDP*tmpDecomp;
    end
end

% Constrain the Choi matrix to be positive definite
constraint = chiSDP > 0;

% Call the solver, minimizing the distance between the vectors of predicted and actual
% measurements
solvesdp(constraint, norm(predictedResults(:) - expResults(:), 2), sdpsettings('verbose',verbose));

out = double(chiSDP);

    function cohVec = pauli_decompose(inputMat)
        cohVec = zeros(4,1);
        for ct = 1:4
            cohVec(ct) = trace(inputMat*pauliOps{ct})/2;
        end
    end
end