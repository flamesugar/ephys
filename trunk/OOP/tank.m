classdef tank
    % TANK Class for TDT Data Tank Server
    
    % DJS 2013
    
    properties (SetAccess = 'public',GetAccess = 'public')
        name                    % Data tank
        block                   % Tank block number
        server  = 'local';      % Tank server (default = 'local')
        verbose = true;         % Print detailed info
    end
    
    properties (SetAccess = 'protected',GetAccess = 'protected')
        TT                      % TTank ActiveX
        TDTfig                  % TTank ActiveX container
    end
    
    properties (SetAccess = 'private',GetAccess = 'public',Dependent = true)
        status                  % Tank status
        blocklist               % Blocks in tank
        currentblock            % Selected block name
        params                  % Event data structure
        tankpath                % Path to tank
        time_start              % Block start time
        time_stop               % Block stop time
    end
    
    methods        
        %% class constructor
        function obj = tank(name,block)
            [obj.TT,obj.TDTfig] = setupTT(obj);
            if nargin >= 1, obj.name = name;    end
            if nargin == 2, obj.block = block;  end
        end
        
        % OpenTank
        function obj = open(obj)
            obj = checkTT(obj);
            s = obj.TT.OpenTank(obj.name,'R');
            if obj.verbose
                if s
                    fprintf('Tank ''%s'' opened succesfully\n',obj.name)
                else
                   disp(obj.TT.GetError);
                end
            end
        end
        
        
        %% Set/Get functions-----------------------------------------------       
        % Set/Get name
        function obj = set.name(obj,name)
            obj.name = name;
            obj = open(obj);
        end
        
        function name = get.name(obj)
            name = obj.name;
        end
        
        % Set/Get block
        function obj = set.block(obj,block)
            b = obj.blocklist; %#ok<MCSUP>
            obj = selectBlock(obj,b{block});
            obj.block = block;
        end
        
        function block = get.block(obj)
            block = obj.block;
        end
        
        % Get currentblock        
        function cb = get.currentblock(obj)
            obj = checkTT(obj);
            cb = obj.TT.CurBlockName;
        end
        
        % Get blocklist        
        function blocklist = get.blocklist(obj)
            if ~isa(obj.TT,'COM.TTank_X'), blocklist = {''}; return; end
            blocklist{1} = [];
            bidx = 2;
            obj.TT.QueryBlockName(0);   %initialize block query
            while ~strcmp(blocklist{bidx-1},'')
                blocklist{bidx} = obj.TT.QueryBlockName(bidx-1); %#ok<AGROW>
                bidx = bidx + 1;
            end
            blocklist([1 end]) = [];    % erase first and last empties
            % properly sort blocklist
            for i = 1:length(blocklist)
                j = find(blocklist{i}=='-',1,'last');
                n(i) = str2double(blocklist{i}(j+1:end)); %#ok<AGROW>
            end
            [~,idx] = sort(n);
            blocklist = blocklist(idx)';
        end
        
        % Get eventcodes        
        function p = get.params(obj)
            obj = checkTT(obj);
            obj.TT.CreateEpocIndexing;
            obj.TT.ResetFilters;
            % get epoch names
            i = 1;
            while true
                p(i).event = obj.TT.GetEpocCode(i-1); %#ok<AGROW>
                if isempty(p(i).event)
                    p(i) = []; %#ok<AGROW>
                    break
                end
                p(i).vals  = obj.TT.GetEpocsV(p(i).event,0,0,10^6)'; %#ok<AGROW>
                p(i).uvals = unique(p(i).vals(:,1)); %#ok<AGROW>
                i = i + 1;
            end

        end
               
        % Get date/time info
        function d = get.time_start(obj)
            obj = checkTT(obj);
            t = obj.TT.CurBlockStartTime;
            d = obj.TT.FancyTime(t,'Y-O-D H:M:S');
        end
        
        function d = get.time_stop(obj)
            obj = checkTT(obj);
            t = obj.TT.CurBlockStopTime;
            d = obj.TT.FancyTime(t,'Y-O-D H:M:S');
        end
        
        % Set/Get status
        function s = get.status(obj)
            if isa(obj.TT,'COM.TTank_X')
                a = obj.TT.CheckTank(obj.name);
                switch a
                    case 67,    s = 'closed';
                    case 79,    s = 'open';
                    case 82,    s = 'record';
                    otherwise,  s = 'unknown';
                end
            else
                s = 'closed';
            end
        end
        
        
        %% Helper functions
        % Permute parameters
        function p = permutepars(obj,parid)
            % p = permutepars(parid)
            %
            % Returns permutations along n-parameters
            %
            % PARID refers to the parameter index in obj.params array.
            
            pars = obj.params(parid);
            
            uvals = {pars.uvals};
            
            p = uvals{1};
            % permute values of additional dimensions
            for i = 2:length(uvals)
                n = length(uvals{i});
                p = repmat(p',1,n)';
                np = repmat(uvals{i}',size(p,1)/n,1);
                p(:,i) = np(:);
            end
            
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        %% ----------------------------------------------------------------
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        % Close tank object
        function close(obj)
            closeTT(obj);
        end
        
        %---------------------------------
        % handle 'destruction'
        function delete(obj)
            closeTT(obj);
        end
        
        
    end
        
    methods(Access = 'protected', Hidden = true)
        % instantiate TTank ActiveX control
        function [TT,TDTfig] = setupTT(obj)
            TDTfig = figure('Visible','off','Name','TTankFig');
            TT     = actxcontrol('TTank.X','parent',TDTfig);
            TT.ConnectServer(obj.server,'Me'); 
            TT.GetEnumTank(0); 
            if obj.verbose
                fprintf('Connected to tank server ''%s''\n',obj.server)
            end
        end
        
        % properly close tank and delete ActiveX control and figure
        function obj = closeTT(obj)
            obj = checkTT(obj);
            obj.TT.CloseTank;
            obj.TT.ReleaseServer;
            delete(obj.TT)
            obj.TT = [];
            close(obj.TDTfig);
            if obj.verbose
                fprintf('Tank closed and server released\n')
            end
        end
        
        % check for TT
        function obj = checkTT(obj)
           if ~isa(obj.TT,'COM.TTank_X')
               [obj.TT,obj.TDTfig] = setupTT(obj);
           end
        end      
           
        % select block
        function obj = selectBlock(obj,block)
            if nargin == 1 || isempty(block), return; end
            obj = checkTT(obj);
            s = obj.TT.SelectBlock(block);
            if obj.verbose
                if s
                    fprintf('Block ''%s'' selected\n',block)
                else
                    disp(obj.TT.GetError)
                end
            end
        end
                
    end
    
end