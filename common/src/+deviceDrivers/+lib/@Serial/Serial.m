 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name : SerialWrapper
 %
 % Author/Date : C.B. Lirakis / 7-Jul-09
 %
 % Description : Object to manage access to devices connected to a serial
 % port. This inherits the properties from DAObject. 
 %
 % Restrictions/Limitations :
 %
 % Change Descriptions :
 %
 % Classification : Unclassified
 %
 % References :
 %
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %                CBL
 %
 % RCS header info.
 % ----------------
 % $RCSfile$
 % $Author$
 % $Date$
 % $Locker$
 % $Name$
 % $Revision$
 %
 % $Log: $
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %
classdef Serial < deviceDrivers.lib.deviceDriverBase
    properties 
        % I/O through this.
        FileDescriptor;
        % Port name  - to be read/written in configuration file
        PortName;
        Initialized = false;
        PauseTime = 0.05;
        TimeOut = 3; % seconds
    end

    methods
        %%
        % Constructor ---------------------------------
        % must supply com port parameters such as name.
        % We may need to specify baud rate etc later. 
        function obj = Serial(ComPort)
            obj = obj@deviceDrivers.lib.deviceDriverBase('SerialObject');
            obj.Initialized = false;
         end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : OpenDevice
        %
        % Description : Open the serial port. 
        %
        % Inputs : 
        %
        % Returns : 
        %
        % Error Conditions : 
        %      0 SUCCESS!
        %
        % Unit Tested on: 
        %
        % Unit Tested by: CBL
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function connect(obj, port)
            obj.LastError = obj.NoError;
            if obj.Initialized
                fclose(obj.FileDescriptor);
            end
            if nargin>1
                % use the port provided, otherwise assume
                % it was initialized elsewhere.
                obj.PortName = port;
            end
            obj.FileDescriptor = serial(obj.PortName);
            fopen(obj.FileDescriptor);
            if (strcmp(obj.FileDescriptor.status,'closed'))
                LastError = obj.OpenFail;
                if (obj.UseErrorDialog)
                    errordlg('Error opening Com Port');
                else
                    warning('Error opening Com Port');
                end
            else
                obj.Initialized = true;
            end
        end % Method OpenDevice
        
        function close(obj)
            if obj.Initialized
                fclose(obj.FileDescriptor);
            end
        end
        
        % alternative method for closing
        function disconnect(obj)
            obj.close()
        end
        
        %
        % Destructor method
        %
        function delete(obj)
            % This function does not close correctly
            if obj.Initialized
                fclose(obj.FileDescriptor);
            end
        end
        % 
        % Write data to port. 
        %
        function Write(obj, string)
            if obj.Initialized
                fprintf(obj.FileDescriptor,'%s',string);
            end
        end
        
        function val = Read(obj)
            val = '';
            if obj.Initialized
                if (obj.FileDescriptor.BytesAvailable > 0)
                    val = fscanf(obj.FileDescriptor,'%s');
                else
                    obj.LastError = obj.NoData;
                    
                end
            end
        end
        
        function val = ReadRetry(obj)
           n = clock;
           val = '';
           while ((etime(clock,n) < obj.TimeOut) && (strcmp(val,'')))
               pause(obj.PauseTime);
                val = obj.Read();
           end
        end
        
        function val = WriteAndRead(obj,string)
           obj.Write(string);
           val = obj.ReadRetry();
        end
       %
        % Dump the properties of the serial port. Debugging tool
        %
       function none = Dump(obj)
            obj.Dump@DAObject;
            fprintf('Port Name: %s \n', ...
                obj.PortName);
       end
       %
       % Dialog for configuring com port.
       %
       function Configure(obj)
           % 
           % Todo use instrfind to see which com ports are 
           % available.
           ans = SerialConfiguration();
           if strcmp(ans.Answer,'Yes')
               obj.PortName = ans.Port;
               obj.OpenDevice;
           end
       end
       %
       % Write all parameters associated with com port to a config file
       %
       function SaveParameters(obj)
           error('Not completed');
       end
       %
       % Read back parameters from config file. 
       %
       function LoadParameters(obj)
           error('Not completed');
       end
    end
end