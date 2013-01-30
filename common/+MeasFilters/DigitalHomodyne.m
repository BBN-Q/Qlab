classdef DigitalHomodyne < MeasFilters.MeasFilter
   
    properties
        IFfreq
        samplingRate
        integrationStart
        integrationPts
    end
    
    methods
        function obj = DigitalHomodyne(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.IFfreq = settings.IFfreq;
            obj.samplingRate = settings.samplingRate;
            obj.integrationStart = settings.integrationStart;
            obj.integrationPts = settings.integrationPts;
        end
        
        function out = apply(obj, data)
            import MeasFilters.*
            data = apply@MeasFilters.MeasFilter(obj, data);
            
            demodSignal = digitalDemod(data, obj.IFfreq, obj.samplingRate);

            %Box car filter the demodulated signal (as a column vector, for
            %no good reason)
            %The first time we just assign
            if isempty(obj.accumulatedData)
                obj.accumulatedData = 2*mean(demodSignal(obj.integrationStart:obj.integrationStart+obj.integrationPts-1,:))';
            else
                obj.accumulatedData = obj.accumulatedData + 2*mean(demodSignal(obj.integrationStart:obj.integrationStart+obj.integrationPts-1,:))';
            end
            obj.avgct = obj.avgct + 1;
            out = obj.accumulatedData / obj.avgct;
        end
        
        function out = get_data(obj)
            out = obj.accumulatedData / obj.avgct;
        end
    end
    
    
end