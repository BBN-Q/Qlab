classdef msgmanager < handle
%MSGMANAGER Summary of this class goes here
%   Detailed explanation goes here

   properties
       message_buffer;
       message_buffer_max = 25;
       num_display_lines = 4;
       handles;
       type;
       TYPE_APSGUI = 0;
       TYPE_APSINSERT = 1;
   end

   methods 
        function mm = msgmanager(handles)
            mm.handles = handles;
            mm.message_buffer = cell(size(mm.message_buffer_max));
            for idx = 1:mm.message_buffer_max
                mm.message_buffer{idx} = '';
            end
            if isfield(handles, 'sl_msg')
                set(handles.sl_msg,'Max',mm.message_buffer_max);
                set(handles.sl_msg,'Min',1);
                set(handles.sl_msg,'Value',1);
                mm.update_controls(1);
                mm.type = mm.TYPE_APSGUI;
            else
                mm.type = mm.TYPE_APSINSERT;
            end
        end
        
        function disp(self, line)
            disp(line);
            % store line in buffer
            for idx = self.message_buffer_max:-1:2
                self.message_buffer{idx} = self.message_buffer{idx-1};
            end
            self.message_buffer{1} = line;
            if self.type == self.TYPE_APSGUI
                self.update_controls(1);
                set(self.handles.sl_msg,'Value',1);
            else
                set(self.handles.message_window, 'String',self.message_buffer)
            end
            drawnow();
        end
        
        function update_controls(self, idx)
            if (idx < 1)
                idx = 1;
            end
            if (idx > self.message_buffer_max - self.num_display_lines)
                idx = self.message_buffer_max - self.num_display_lines;
            end
            for hidx = 1:self.num_display_lines
                dl = eval(sprintf('self.handles.txt_msg_%i', hidx));
                set(dl, 'String', self.message_buffer{idx + hidx - 1});
            end
        end

   end
   
end 
