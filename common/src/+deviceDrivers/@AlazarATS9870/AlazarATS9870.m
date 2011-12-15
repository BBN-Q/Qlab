classdef AlazarATS9870 < deviceDrivers.lib.deviceDriverBase
    % Class driver file for Alazar Tech ATS9870 PCI digitizer
    %
    % Author(s): Colm Ryan
    % Code started: 29 November 2011
    
    properties (Access = public)
        
        
        model_number = 'ATS9870';
        
        %Not sure what this is for (probably just compatibility with other
        %instruments
        Address
        
        %Location of the Matlab include files with the SDK
        includeDir = 'C:\AlazarTech\ATS-SDK\6.0.3\Samples_MATLAB\Include'
        
        %Dictionary of defined variables
        defs = containers.Map()
        
        %Assume for now we have only one board in the computer so hardcode
        %the IDs
        systemId = 1
        boardId = 1
        
    end
    
    methods (Access = public)
        %Constuctor which loads definitions and dll
        function obj = AlazarATS9870()
            
            %Add the include directory to the path
            addpath(obj.includeDir)
            
            %Load the definitions
            obj.load_defs();
            
            %Load the interface DLL
            %Alazar provides a precompiled thunk helper and prototype file
            %for speed so we'll use their helper function
            if ~alazarLoadLibrary()
                error('ATSApi.dll is not loaded\n');
            end
        end
        
        function load_defs(obj)
            %Parse the definition file and return everything in a structure
            %This is a bit of a hack but I want to leave the defs file
            %untounched so we can easily update the SDK.
            %Basically we call the scipt and then save every variable in a
            %dictionary
            AlazarDefs
            defNames = who;
            %Matlab could really use a foreach
            for ct = 1:length(defNames)
                if ~strcmp(defNames{ct},'obj')
                    obj.defs(defNames{ct}) = eval(defNames{ct});
                end
            end
            
        end
        
        %Dummy function to connect
        function connect(obj, Address)
            %If we specify an new address, use it (although it's not clear
            %what for. 
            obj.Address    = Address;
        end    
        
        %Dummy function to disconnect
        function disconnect(obj)
        end    
        
        %Dummy function to reset (I'm not sure what calls this). 
        
        
        
        
    end
    
end





