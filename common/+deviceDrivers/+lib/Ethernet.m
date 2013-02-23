%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : Ethernet
%
% Author/Date : C.B. Lirakis / 17-Jul-09
%
% Description : Object to manage access to devices connected to a Ethernet
% device. This inherits the properties from DAObject. Note that
% I specifically do not use visa here. I'm not sure how widely supported
% it is on non-windows platforms.
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
% $Revision$
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef Ethernet < deviceDrivers.lib.deviceDriverBase
    properties
        % Vendor name - Config file
        VendorName;
        % Board index, are we supporting multiple IO boards?
        % It's possible. - Config
        BoardIndex;
        % Instrument address.
        Address;

        % Parameters below this line are not saved.
        % I/O through this.
        EthernetHandle;
        % The next variable is only used in the linux variant of the calls.
        InstrumentHandle;
        CardOpen;
        
        % Initialization environment
        InitEnvironment;
    end
    properties (Constant = true)
        % Add to error class.
        EthernetCardOpen  = {-2, 'Ethernet: Card still open.'};
        InsufficientParameters = {-3, 'Ethernet: Supply Board index and vendor'};
        OpenFailed    = {-4, 'Ethernet: Open failed'};
        AddressFailed = {-5, 'Ethernet: Set address failed.'};
        NotOpen       = {-6, 'Ethernet: Card not open.'};
        ReadFailed    = {-7, 'Ethernet: Read failed.'};
        BadParameter  = {-8, 'Ethernet: Parameter of wrong type.'};
        % End of error list

        Execute = 'X';
        % Other universal commands.
        % Command group 0
        Attention      = {'ATN', 0, -1};
%         Clear          = {'DCL', 0, -1};
        InterfaceClear = {'IFC', 0, -1};
        LocalLockout   = {'LLO', 0, -1};
        RemoteEnable   = {'REN', 0, -1};
        SeralPollOn    = {'SPE', 0, -1};
        SeralPollOff   = {'SPD', 0, -1};
        END            = {'EOI', 0, -1};
    end
  
    methods
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Ethernet Constructor
        %
        % Description : At a minimum the board vendor id and
        % target address must be supplied. The board index will
        % default to zero if not specificed
        %
        % Inputs :  Vendor - Vendor id. Please see :
        %           http://www.mathworks.com/access/helpdesk/help/toolbox/instrument/index.html?/access/helpdesk/help/toolbox/instrument/Ethernet.html&http://www.google.com/search?q=matlab+Ethernet+command&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a
        %           for a list of names of supported vendors.
        %
        %           address - target address of Ethernet device.
        %           index   - Ethernet driver board index. Usually 0.
        %
        % Returns :
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on: 22-Jul-09
        %
        % Unit Tested by: CBL
        %
        % $Revision$
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = Ethernet(Vendor, index)
            % import dev.DAObject.DAObject;
            
            % Initialize Super class
%             obj           = obj@dev.DAObject.DAObject();
            obj.Name      = 'EthernetObject';
            obj.CardOpen  = false;
            if nargin > 1
                obj.VendorName = Vendor;
                obj.BoardIndex = index;
            else
                obj.VendorName = 'ni';
                obj.Address    = 0; 
                obj.BoardIndex = 0;
            end
            obj.CardOpen = true;
        end
        %%
        function disconnect(obj)
            try
                if obj.CardOpen
                    if isunix
                        obj.EthernetHandle.ibonl(obj.InstrumentHandle, 0);
                    else
                       fclose(obj.deviceObj_awg);
                       delete(obj.deviceObj_awg);
                    end
                end
            catch HOTPOTATO
                disp('Ethernet object already closed');
%                 disp(lasterror);
            end
        end
        %%
        % Destructor method
        %
        function delete(obj)
            obj.disconnect;
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Set method for Address
        %
        % Description : Set the address, if the card is open
        % close and reopen it. 
        %
        % Inputs :
        %
        % Returns :
        %
        % Error Conditions :
        %      true SUCCESS!
        %
        % Unit Tested on: 
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = set.Address(obj, value)
            
            % error check the value.
            if (value<0) || (value>31)
                obj.LastError = obj.AddressFailed;
                return;
            end
            obj.Address = value;
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : SetCard
        %
        % Description :
        %
        % Inputs :
        %
        % Returns :
        %
        % Error Conditions :
        %      true SUCCESS!
        %
        % Unit Tested on: 22-Jul-09
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function SetCard(obj, Vendor, index)
            if obj.CardOpen
                obj.LastError = obj.EthernetCardOpen; % Need to close card first.
                return
            end
            if nargin < 2
                if (obj.UseErrorDialog)
                    errordlg('You must supply the vendor name and board index.');
                else
                    error('You must supply the vendor name and board index.');
                end
                obj.LastError = obj.InsufficientParameters; % Insufficient parameters.
            end
            obj.VendorName = Vendor;
            obj.BoardIndex = index;
        end % Method Set Card
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : connect
        %
        % Description : Machine independent way to open 
        % a Ethernet device
        %
        % Inputs : Address - if not supplied, this open
        % will use the address defined in the class.
        %
        % Returns : none
        %
        % Error Conditions :
        %      true SUCCESS!
        %
        % Unit Tested on: 22-Jul-09
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function connect(obj, Address)
            if nargin > 1
                % if we specify an new address, use it.
                obj.Address    = Address;
            end
            % Can't reopen the card, close it first.
            if obj.CardOpen
                if isunix
                    obj.EthernetHandle.ibonl(obj.InstrumentHandle, 0);
                else
                   fclose(obj.EthernetHandle);
                end
            end

            % Perform the open
            if isunix
                %Arguments to FMH library are:
                % 
                % brd board index
                % pad primary device address
                % sad secondary device address
                % tmo timeout value 11 = 1 s
                % send_eoi - send an end of line
                % eos      - end of line type.
                %
                obj.EthernetHandle = Ethernetio;   % Initialze class
                obj.InstrumentHandle = obj.EthernetHandle.ibdev( ...
                    obj.BoardIndex , ...
                    obj.Address , ...
                    0,...                  % Secondary address
                    11, ...                % Timeout, see pge 51 of doc.
                    1, ...                 % send EOL or not (1=true)
                    0);                    % EOL type. (0=crlf)
                if obj.InstrumentHandle < 0
                    errordlg('Error opening Ethernet Port');
                    return;
                end
                % With is library ou can open many devices with the ame
                % card online. Should be careful. 
                obj.EthernetHandle.ibonl( obj.InstrumentHandle, 1);
                %
                % timeout is not set correctly in above call. 
                % set it to 1s.
                %
                obj.EthernetHandle.ibtmo(obj.InstrumentHandle,11);
            else
                obj.EthernetHandle = Ethernet( obj.VendorName, obj.BoardIndex, ...
                    obj.Address);
                
                % 512 bytes (the default) makes for a tiny buffer. 1MB is
                % pretty big, but it will accomodate the amount of data we
                % need to xfer from the network analyzer at the moment
                % (20001 points * 2 numbers per point * 20 chars per number
                % = 800040 bytes) -- and we're not in danger of running out
                % of memory
                try
                    obj.EthernetHandle.InputBufferSize = obj.bufferSize;
                catch %#ok<CTCH>
                    obj.EthernetHandle.InputBufferSize = 1048576;
                end
                
                fopen(obj.EthernetHandle);
                if (strcmp(obj.EthernetHandle.status,'closed'))
                    obj.LastError = obj.OpenFailed;
                    if (obj.UseErrorDialog)
                        errordlg('Error opening Ethernet Port');
                    else
                        warning('Error opening Ethernet Port');
                    end
                end
            end
            obj.CardOpen = true;
        end % Method Device Open
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Write
        %
        % Description : Write a string to a Ethernet device
        %
        % Inputs : string to write
        %
        % Returns : true on success
        %
        % Error Conditions :
        %      true SUCCESS!
        %
        % Unit Tested on: 22-Jul-09
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = Write(obj, string)
            % Emulate ellipsis at a later date, assume user will format
            % string.
            if obj.CardOpen
                if isunix
                    rc = obj.EthernetHandle.write( obj.InstrumentHandle, ...
                        string, 4);
                else
                    fprintf( obj.EthernetHandle, string);
                end
                if obj.DebugLevel>2
                    fprintf('Ethernet Write: %s Value: %s Error: %s\n', ...
                        obj.Name, ...
                        string, ...
                        obj.LastError{2});
                end
                obj.LastError = obj.NoError;
                val = true; % represents success.
            else
                obj.LastError = obj.NotOpen;
                val = false;
            end
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Read
        %
        % Description : Machine independent read function
        %
        % Inputs : 
        %
        % Returns : string from read. 
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on: 22-Jul-09
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rc = Read( obj)
            obj.LastError = obj.NoError;
            if obj.CardOpen
                if isunix
                    rv = obj.EthernetHandle.ibrd( obj.InstrumentHandle, 128);
                    if obj.EthernetHandle.ibcnt.Value > 0
                        rc = char(obj.EthernetHandle.buffer.Value);
                    else
                        obj.LastError = obj.ReadFailed;
                        rc = ' ';
                    end
                else
                    rc = fscanf(obj.EthernetHandle);
                end
            else
                obj.LastError = obj.NotOpen;
                rc = ' ';
            end
            if obj.DebugLevel>2
                fprintf('Ethernet Read %s %s\n', obj.Name, rc);
            end
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Query
        %
        % Description : Machine independent query (write->read) function
        %
        % Inputs : 
        %
        % Returns : string from read. 
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL/mookerji
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rc = Query(obj, string)
            obj.LastError = obj.NoError;
            % Emulate ellipsis at a later date, assume user will format
            % string.
            if obj.CardOpen
                if isunix
                else
                    rc = query( obj.EthernetHandle, string);
                end
                if obj.DebugLevel>2
                    fprintf('Ethernet Write: %s Value: %s Error: %s\n', ...
                        obj.Name, ...
                        string, ...
                        obj.LastError{2});
                end
                obj.LastError = obj.NoError;
            else
                obj.LastError = obj.NotOpen;
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : reset
        %
        % Description : Common between devices.
        %
        % Inputs :
        %
        % Returns :
        %
        % Error Conditions : NONE
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       function reset(obj)
            obj.LastError = 0;
            if obj.CardOpen
                if isunix
                    obj.EthernetHandle.Write('ATN');
                    obj.EthernetHandle.Write('DCL');
                else
                    fprintf(obj.EthernetHandle, 'ATN');
                    fprintf(obj.EthernetHandle, 'DCL');
                end
            else
                obj.LastError = obj.NotOpen;
            end
        end
        %%
        function remote_enable(obj)
            obj.LastError = 0;
            if obj.CardOpen
                if isunix
                    obj.EthernetHandle.Write('REN');
                else
                    fprintf(obj.EthernetHandle, 'REN');
                end
            else
                obj.LastError = obj.NotOpen;
           end
        end

        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Dump
        %
        % Description : Debugging tool 
        %
        % Inputs :
        %
        % Returns :
        %
        % Error Conditions :
        %      0 SUCCESS!
        %
        % Unit Tested on: 22-Jul-09
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function none = Dump(obj)
            obj.Dump@dev.DAObject.DAObject;
            fprintf('Ethernet Vendor: %s Target Address: %d Card Index: %d\n', ...
                obj.VendorName, obj.Address, obj.BoardIndex);
            if obj.CardOpen
                fprintf('Ethernet Interface is open and online.\n');
            else
                fprintf('Ethernet Interface has not yet been opened.\n');
            end
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : Configure
        %
        % Description : Bring up a gui to enter the parameters.
        %
        % Inputs : none
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
        function Configure(obj)
            % this function should be deprecated. It call's a GUI, although
            % Ethernet configuration is handled in LoadParameters. Also, note
            % that Ethernet_Config.m/.fig is in the @Ethernet_Wrapper directory,
            % but that it needs to be modified for Configure(obj) to see
            % it. The function needs to be imported here for it work as
            % well. - Buro
            if obj.CardOpen
                errordlg('The Ethernet card is open, closing it.');
                obj.CardOpen  = false;
                fclose(obj.EthernetHandle);
            end
%             Result = Ethernet_Config('VendorID', obj.VendorName, ...
%                 'Address', obj.Address, 'CardIndex', obj.BoardIndex);
%             if strcmp(Result.answer,'Yes')
%                 obj.VendorName = Result.VendorID;
%                 obj.Address    = Result.Address;
%                 obj.BoardIndex = Result.Index;
%                 msgbox('Opening Ethernet card with new parameters.');
%                 obj.connect;
%             end
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name : SaveParameters
        %
        % Description :
        %
        % Inputs : structure to populate with updated values.
        %
        % Returns : NONE
        %
        % Error Conditions : NONE
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function SaveParameters(obj, environment)
            environment.Ethernet.vendor = obj.VendorName;
            environment.Ethernet.boardindex = obj.BoardIndex;
            eval(['environent.',obj.class,'.',obj.Name, ...
                 '.Address = obj.Address']);
        end
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Function Name :
        %
        % Description :
        %
        % Inputs :
        %
        % Returns :
        %
        % Error Conditions : NONE
        %
        % Unit Tested on:
        %
        % Unit Tested by: CBL
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function LoadParameters(obj, environment)
            Parameters = environment.GetValue('Ethernet');
            if environment.LastError{1} == 0 
                %
                % See if the Ethernet port is specified, if not prompt user
                %
                % These are independent of the device and should 
                % occur once per file. 
                %
                if ~(isempty(Parameters.vendor) && isempty(Parameters.boardindex))
                    obj.VendorName = Parameters.vendor;
                    obj.BoardIndex = Parameters.boardindex;
                    % Don't do the open here. Load the address elsewhere
                    % The address is device specific.
                    % Not sure what to do when this fails yet.
                else
                    % It doesn't exist, specify now
                    obj.Configure();
                end
            else
                obj.Configure();
            end
            %
            % Now the remaining parameters are board specific
            % The top level device should have set the 
            % DAObject variable Name and we need to get the remaining
            % parameters off that. 
            % Do a get parameters again. 
            obj.InitEnvironment = environment.GetValue('InitParams').(obj.Name);
            if environment.LastError{1} == 0
                if isfield(obj.InitEnvironment,'Address')
                    % This call will execute the open
                    % in the set method.
                    obj.Address = obj.InitEnvironment.Address;
                    obj.connect;
                end
            end
        end
    end % Methods
end
