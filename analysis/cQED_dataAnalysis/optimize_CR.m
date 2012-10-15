function optimize_CR(choiMeas, Uideal)

%Helper function to optimize the CR gate with local rotations
X = [0, 1;1 0]; Y = [0 -1i;1i 0]; Z = [1 0;0 -1];

%Create the pauli operator strings
[~, pauliStrs] = paulis(2);

pauliMeas = choi2pauliMap(choiMeas);
idealPauli = unitary2pauli(Uideal);

% %%First let's try single-qubit Z rotations
%     function error = fitFunc(thetas)
%         %Modify Uideal by the Z rotations
%         Zrot1 = expm(-1i*thetas(1)/2*Z);
%         Zrot2 = expm(-1i*thetas(2)/2*Z);
%         rotatedU = kron(Zrot1,Zrot2)*Uideal;
%         choiRotated = unitary2choi(rotatedU);
%         chiRotated = choi2chi(choiRotated);
%         processFidelity = real(trace(chiRotated*chiMeas));
%         gateFidelity = (2^2*processFidelity+1)/(2^2+1);
%         error = 1-gateFidelity;
%     end
% 
% %Optimize the rotations
% bestThetas = fminsearch(@fitFunc, [0,0])

%Generic rotations
    function fixedPauli = fixPauli(thetas)
        %Modify Uideal by the rotations
        rot1Before = expm(-1i*thetas(1)/2*Z)*expm(-1i*thetas(2)/2*X)*expm(-1i*thetas(3)/2*Z);
        rot2Before = expm(-1i*thetas(4)/2*Z)*expm(-1i*thetas(5)/2*X)*expm(-1i*thetas(6)/2*Z);
        rot1After = expm(-1i*thetas(7)/2*Z)*expm(-1i*thetas(8)/2*X)*expm(-1i*thetas(9)/2*Z);
        rot2After = expm(-1i*thetas(10)/2*Z)*expm(-1i*thetas(11)/2*X)*expm(-1i*thetas(12)/2*Z);
        fixedPauli = unitary2pauli(kron(rot1After, rot2After))*pauliMeas*unitary2pauli(kron(rot1Before, rot2Before));
    end
    function error = fitFunc(thetas)
        
        gateFidelity = trace(fixPauli(thetas)*idealPauli)/16;
        error = 1-gateFidelity;
    end

%Optimize the rotations
bestThetas = fminsearch(@fitFunc, zeros(1,12), optimset('Display','iter','MaxIter',1e4,'MaxFunEvals',1e4));

correctedPauliMap = fixPauli(bestThetas);

cmap = [hot(50); 1-hot(50)];
cmap = cmap(19:19+63,:); % make a 64-entry colormap


figure()
imagesc(real(correctedPauliMap),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^2);
set(gca, 'XTickLabel', pauliStrs);

set(gca, 'YTick', 1:4^2);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator', 'FontSize', 12);
ylabel('Output Pauli Operator', 'FontSize', 12);
title('Pauli Map Constrained Process Tomography','FontSize',14);




end