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
            
            %Box car filter the demodulated signal
            if ndims(demodSignal) == 2
                obj.latestData = 2*mean(demodSignal(obj.integrationStart:obj.integrationStart+obj.integrationPts-1,:));
            elseif ndims(demodSignal) == 4
                obj.latestData = 2*mean(demodSignal(obj.integrationStart:obj.integrationStart+obj.integrationPts-1,:,:,:));
            else
                error('Only able to handle 2 and 4 dimensional data.');
            end
                
            obj.accumulate();
            out = obj.get_data();
        end
    end
    
    
end