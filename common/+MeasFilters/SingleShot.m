% A single-shot fidelity estimator

% Author/Date : Blake Johnson and Colm Ryan / February 12, 2013

% Copyright 2013 Raytheon BBN Technologies
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
classdef SingleShot < MeasFilters.MeasFilter
    
    properties
        groundData
        excitedData
        pdfData
        analysed = false
        analysing = false
        bestIntegrationTime
        logisticRegression = false
        saveKernel = true
    end
    
    methods
        function obj = SingleShot(label, settings)
            obj = obj@MeasFilters.MeasFilter(label, settings);
            if isfield(settings, 'logisticRegression')
                obj.logisticRegression = settings.logisticRegression;
            end
        end
        
        function out = apply(obj, src, ~)
            % just grab (and sort) latest data from source 
            % data comes recordsLength x numShots segments
            obj.groundData = src.latestData(:,1:2:end);
            obj.excitedData = src.latestData(:,2:2:end);
            out = [];
        end
        
        function out = get_data(obj)
            %If we don't have all the data yet return empty
            %Since we only have one round robin the ground data is either
            %unset or NaN
            if isempty(obj.groundData) || isnan(obj.groundData(1))
                out = [];
                return
            end
            
            if ~obj.analysing
                obj.analysing = true;

                % return histogrammed data
                obj.pdfData = struct();
                
                groundMean = mean(obj.groundData, 2);
                excitedMean = mean(obj.excitedData, 2);
                distance = mean(groundMean - excitedMean);
                fprintf('distance: %g\n', distance);
                bias = mean(groundMean + excitedMean)/distance;
                fprintf('bias: %g\n', bias(end));
                
                % construct matched filter kernel and apply it
                kernel = conj(groundMean - excitedMean) ./ var(obj.groundData,0,2);
                %need a criterion to set kernel to  zero when the difference is
                %too small (also prevents kernel from diverging when var->0
                %at the beginning of the record
                kernel = kernel.*(abs(groundMean-excitedMean)>(1e-3*distance));
                fprintf('norm: %g\n', sum(abs(kernel)));
                % normalize
                kernel = abs(2.0/distance) * kernel / sum(abs(kernel));
                
                if isreal(kernel)
                    kernel = myhilbert(kernel);
                end
                
                if obj.saveKernel
                    dlmwrite(strcat('kernel_',obj.dataSource,'_real.csv'), real(kernel));
                    dlmwrite(strcat('kernel_',obj.dataSource,'_imag.csv'), imag(kernel));
                end
                
                weightedGround = bsxfun(@times, obj.groundData, kernel);
                weightedExited = bsxfun(@times, obj.excitedData, kernel);
                groundIData = real(weightedGround);
                excitedIData = real(weightedExited);
                groundQData = imag(weightedGround);
                excitedQData = imag(weightedExited);
                
                %Take cummulative sum up to each timestep
                intGroundIData = cumsum(groundIData, 1) - real(bias);
                intExcitedIData = cumsum(excitedIData, 1) - real(bias);
                intGroundQData = cumsum(groundQData, 1) - imag(bias);
                intExcitedQData = cumsum(excitedQData, 1) - imag(bias);
                Imins = min(min(intGroundIData, intExcitedIData), [], 2);
                Imaxes = max(max(intGroundIData, intExcitedIData), [], 2);
                
                %Loop through each integration point; estimate the CDF and
                %then calculate best measurement fidelity
                numTimePts = size(intGroundIData,1);
                fidelities = zeros(numTimePts,1);
                for intPt = 2:2:numTimePts
                    %Setup bins from the minimum to maximum measured voltage
                    bins = linspace(Imins(intPt), Imaxes(intPt));
                    
                    %Use cheap histogramming to estimate the PDF for the ground and excited states
                    gPDF = hist(intGroundIData(intPt,:), bins);
                    ePDF = hist(intExcitedIData(intPt,:), bins);
                    
                    fidelities(intPt) = sum(abs(gPDF-ePDF))/sum(gPDF + ePDF);
                end
                
                %reduce fidelities so that it doesn't integrate longer than
                %necessary, DR 150112 
%                 dfid = diff(fidelities(1:2:end));
%                 for kk=1:2:length(fidelities)-2
%                     if abs(dfid((kk+1)/2))<0.001 && fidelities(kk)>0.6  %set some threshold to prevent noise giving false steady state
%                         break
%                     end
%                 end
%                 [maxFidelity_I, intPt] = max(fidelities(1:kk));
                [maxFidelity_I, intPt] = max(fidelities);
                obj.bestIntegrationTime = intPt;
                fprintf('Best integration time found at %d decimated points out of %d\n', intPt, numTimePts);
                % now redo the calculation with KDEs to get a more accurate
                % estimate
                bins = linspace(Imins(intPt), Imaxes(intPt));
                gPDF = ksdensity(intGroundIData(intPt,:), bins);
                ePDF = ksdensity(intExcitedIData(intPt,:), bins);
                % report "assignment fidelity" = 1-0.5*(1-F)
                obj.pdfData.maxFidelity_I =  1-0.5*(1-0.5*(bins(2)-bins(1))*sum(abs(gPDF-ePDF)));
                obj.pdfData.bins_I = bins;
                obj.pdfData.gPDF_I = gPDF;
                obj.pdfData.ePDF_I = ePDF;
                
%                 tmpData = intGroundIData(intPt,:);
%                 [mu, sigma] = normfit(tmpData(tmpData<0));
                [mu, sigma] = normfit(intGroundIData(intPt,:));
                obj.pdfData.g_gaussPDF_I = normpdf(obj.pdfData.bins_I, mu, sigma);
%                 tmpData = intExcitedIData(intPt,:);
%                 [mu, sigma] = normfit(tmpData(tmpData>0));
                [mu, sigma] = normfit(intExcitedIData(intPt,:));
                obj.pdfData.e_gaussPDF_I = normpdf(obj.pdfData.bins_I, mu, sigma);
                
                %Calculate the kernel density estimates for the other
                %quadrature too
                obj.pdfData.bins_Q = linspace(min([intGroundQData(intPt,:), intExcitedQData(intPt,:)]), max([intGroundQData(intPt,:), intExcitedQData(intPt,:)]));
                obj.pdfData.gPDF_Q = ksdensity(intGroundQData(intPt,:), obj.pdfData.bins_Q);
                obj.pdfData.ePDF_Q = ksdensity(intExcitedQData(intPt,:), obj.pdfData.bins_Q);
                obj.pdfData.maxFidelity_Q = 1-0.5*(1-0.5*(obj.pdfData.bins_Q(2)-obj.pdfData.bins_Q(1))*sum(abs(obj.pdfData.gPDF_Q-obj.pdfData.ePDF_Q)));
                [mu, sigma] = normfit(intGroundQData(intPt,:));
                obj.pdfData.g_gaussPDF_Q = normpdf(obj.pdfData.bins_Q, mu, sigma);
                [mu, sigma] = normfit(intExcitedQData(intPt,:));
                obj.pdfData.e_gaussPDF_Q = normpdf(obj.pdfData.bins_Q, mu, sigma);

                out = maxFidelity_I + 1j*obj.pdfData.maxFidelity_Q;

                obj.analysed = true;
                
                %Logistic regression
                if obj.logisticRegression
                    allData = cat(1, cat(2, real(obj.groundData)', imag(obj.groundData)'), cat(2, real(obj.excitedData)', imag(obj.excitedData)'));
                    prepStates = [zeros(size(obj.groundData,2),1); ones(size(obj.excitedData,2),1)];
                    %Matlab's logistic regression support is quite weak.  The
                    %code below takes forever and overfits.  It looks like in
                    %more recent versions lassoglm might provide some
                    %regularization
                    % betas = glmfit(allData, prepStates, 'binomial');
                    % guessStates = glmval(betas, allData, 'logit');
                    % fidelity = 2*sum(guessStates == prepStates)/size(allData,1) - 1 

                    %Fortunately, liblinear is great!
                    bestAccuracy = 0;
                    bestC = 0;
                    for c = logspace(0,2,5);
                        accuracy = train(prepStates, sparse(double(allData)), sprintf('-c %f -B 1.0 -v 3 -q -s 0',c));
                        if accuracy > bestAccuracy
                            bestAccuracy = accuracy;
                            bestC = c;
                        end
                    end
                    model = train(prepStates, sparse(double(allData)), sprintf('-c %f -B 1.0 -q -s 0',bestC));
                    [predictedState, accuracy, ~] = predict(prepStates, sparse(double(allData)), model);
                    c = 0.95;
                    N = length(predictedState);
                    S = sum(predictedState == prepStates);
                    flo = betaincinv((1-c)/2.,S+1,N-S+1);
                    fup = betaincinv((1+c)/2.,S+1,N-S+1);
                    fprintf('Cross-validated logistic regression accuracy: %.2f\n', bestAccuracy);
                    fprintf('In-place logistic regression fidelity %.2f, (%.2f, %.2f).\n', accuracy(1), 100*flo, 100*fup);
                end
            else
                out = obj.pdfData.maxFidelity_I + 1j*obj.pdfData.maxFidelity_Q;
            end
        end
        
        function reset(obj)
            obj.groundData = [];
            obj.excitedData = [];
            obj.analysed = false;
            obj.analysing = false;
        end
        
        function plot(obj, figH)
            if obj.analysed
                clf(figH);
                axes1 = subplot(2,1,1, 'Parent', figH);
                plt_fcn = @plot; %@semilogy
                plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.gPDF_I, 'b');
                hold(axes1, 'on');
                plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.g_gaussPDF_I, 'b--')
                plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.ePDF_I, 'r');
                plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.e_gaussPDF_I, 'r--')
                allData = [obj.pdfData.gPDF_I(:); obj.pdfData.ePDF_I(:)];
                ylim(axes1, [1e-3*max(allData), 2*max(allData)]); 
                legend(axes1, {'Ground', 'Ground Gaussian Fit', 'Excited', 'Excited Gaussian Fit'})
                snrFidelity = 100-0.5*(100-0.5*100*(obj.pdfData.bins_I(2)-obj.pdfData.bins_I(1))*sum(abs(obj.pdfData.g_gaussPDF_I - obj.pdfData.e_gaussPDF_I)));
                text(0.1, 0.75, sprintf('Fidelity: %.1f%% (SNR Fidelity: %.1f%%)',100*obj.pdfData.maxFidelity_I, snrFidelity),...
                    'Units', 'normalized', 'FontSize', 14, 'Parent', axes1)
                
                %Fit gaussian to both peaks and return the esitmate
                    
                axes2 = subplot(2,1,2, 'Parent', figH);
                semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.gPDF_Q, 'b');
                hold(axes2, 'on');
                semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.g_gaussPDF_Q, 'b--')
                semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.ePDF_Q, 'r');
                semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.e_gaussPDF_Q, 'r--')
                allData = [obj.pdfData.gPDF_Q(:); obj.pdfData.ePDF_Q(:)];
                ylim(axes2, [1e-3*max(allData), 2*max(allData)]); 
                legend(axes2, {'Ground', 'Ground Gaussian Fit', 'Excited', 'Excited Gaussian Fit'})
                text(0.1, 0.75, sprintf('Fidelity: %.1f%%\nIntegration time: %d',100*obj.pdfData.maxFidelity_Q, obj.bestIntegrationTime), 'Units', 'normalized', 'FontSize', 14, 'Parent', axes2)
                drawnow();
            end
        end

        
    end
end