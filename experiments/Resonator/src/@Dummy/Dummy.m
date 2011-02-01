classdef Dummy < Experiment
    
    methods
        
        function name = make_filename(obj) %#ok<MANU>
            name = sprintf('Dummy_data_%s.out',datestr(now(),30));
        end
        
        function take_data(obj)
            obj.fInstruments.pna.abort();
            obj.fInstruments.pna.average_clear();
            
            tic;
            obj.fInstruments.pna.wait();
            obj.fInstruments.pna.block_for_averaging();
%             t=toc;
%             fprintf(obj.data_fid, '%s\n',t);
            
            toc;
            d = obj.fInstruments.pna.sweep_data;
            fprintf(obj.data_fid, '%s',d);
        end
        
        function ordered_preinit(obj)
            net_an_tag = 'pna';
            net_an = obj.fInstruments.(net_an_tag);
            net_an_cfg = obj.fEnvironment.Configuration.InitParams.(net_an_tag);
            
            net_an.GPIBHandle.Timeout = 1;
            net_an.clear();
            net_an.reset();
            net_an.output = 'off';
            net_an.delete_all_measurements();
            
            ord = containers.Map();
            names = fieldnames(net_an_cfg.ordered);
            for i=1:length(names)
                ord(names{i}) = net_an_cfg.ordered.(names{i});
            end
            
            setprop = @(instr,name)...
                (@(value)(subsasgn(instr,substruct('.',name),value)));
            getprop = @(instr,name)...
                (@()(subsref(instr,substruct('.',name))));
            
            spower = setprop(net_an,'power');
            gpower = getprop(net_an,'power');
            
            scenter = setprop(net_an,'sweep_center');
            gcenter = getprop(net_an,'sweep_center');
            
            net_an.define_measurement(ord('meas_name'),ord('meas_type'));
            net_an.select_measurement = ord('meas_name');
            net_an.trace_source       = ord('meas_name');
            
            % this looks overly ugly, but to a great extent it's necessary:
            % the order the properties are set in is sometimes important
            if ord.isKey('power')
                net_an.power              = ord('power'); end
            if ord.isKey('sweep_center')
                net_an.sweep_center       = ord('sweep_center'); end
            if ord.isKey('sweep_span')
                net_an.sweep_span         = ord('sweep_span'); end
            if ord.isKey('sweep_points')
                net_an.sweep_points       = ord('sweep_points'); end
            if ord.isKey('averaging')
                net_an.averaging          = ord('averaging'); end
            if ord.isKey('average_counts')
                net_an.average_counts     = ord('average_counts'); end
            if ord.isKey('trigger_source')
                net_an.trigger_source     = ord('trigger_source'); end
            if ord.isKey('marker1_state')
                net_an.marker1_state      = ord('marker1_state'); end
            if ord.isKey('marker2_state')
                net_an.marker2_state      = ord('marker2_state'); end
            if ord.isKey('timeout')
                net_an.GPIBHandle.Timeout = ord('timeout'); end
            
%             
%             ops = {};
%             
%             record = @()(fprintf('power = %g  center = %g\n',...
%                 str2double(gpower()),str2double(gcenter())));
%             
%             for x=linspace(0,1,3)
%                 power = x;
%                 ops = [ops {{spower, power}}]; %#ok<AGROW>
%                 for y=linspace(0,1,5)
%                     ops = [ops {{scenter, y}}]; %#ok<AGROW>
%                     ops = [ops {{record}}]; %#ok<AGROW>
%                 end
%             end
%             
%             for i=1:length(ops)
%                 ops{i}{1}(ops{i}{2:end});
%             end
%             
%             keyboard
            
        end
        
        function ordered_postinit(obj)
            net_an_tag = 'pna';
            net_an = obj.fInstruments.(net_an_tag);
            
            net_an.output = 'on';
        end
        
        function obj = Dummy(ParameterFile)
            main_path = '';
            import main.Experiment.Experiment;
            obj = obj@main.Experiment.Experiment(ParameterFile, main_path);
        end % constructor Experimental Loop
        
        function delete(obj)
            delete@main.Experiment.Experiment(obj);
            try
                fclose(obj.data_fid);
            catch %#ok<CTCH>
            end
        end % Destructor method
        
        function Run(obj)
            fprintf(obj.data_fid,'# Data taking started at %s\n',datestr(now,0));
            fprintf(obj.data_fid,'%s\n','$$$ Beginning of data');
            Run@main.Experiment.Experiment(obj);
            fprintf(obj.data_fid,'%s\n','$$$ End of data');
            fprintf(obj.data_fid,'# Data taking finished at %s\n',datestr(now,0));
        end % Method Run
        
        function Initialize(obj)
            obj.ordered_preinit();
            Initialize@Experiment(obj);
            obj.ordered_postinit();
            
            root_dir = 'C:\Documents and Settings\Administrator\My Documents\DR_Exp\SVN\qlab\BBN_Experiment\data\';
            filename = obj.make_filename();
            obj.data_fid = fopen([root_dir filename],'w');
            
            ppcfg = util.prettyprintconfig(obj.fEnvironment.Configuration);
            
            start_header = '$$$ Start of header';
            end_header = '$$$ End of header';
            
            fprintf(obj.data_fid,'%s\n',start_header);
            fprintf(obj.data_fid,'%s\n',ppcfg);
            fprintf(obj.data_fid,'%s\n\n',end_header);
        end % Method Initialize
        
        function Finalize(obj)
            Finalize@main.Experiment.Experiment(obj);
            fclose(obj.data_fid);
        end % Method Finalize
        
        function main(obj)
            Initialize(obj);
            Run(obj);
            Finalize(obj);
        end % Method main
     end % Methods
     
 end % class definition.
 