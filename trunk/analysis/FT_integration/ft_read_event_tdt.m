function event = ft_read_event_tdt(tank,block,blockroot,eventname)
% EVENT = ft_read_event_tdt
% EVENT = ft_read_event_tdt(TANK)
% EVENT = ft_read_event_tdt(TANK,BLOCK)
% EVENT = ft_read_event_tdt(TANK,BLOCK,BLOCKROOT)
% EVENT = ft_read_event_tdt(TANK,BLOCK,BLOCKROOT,EVENTNAME)
%
% Read events from TDT tank for use with FieldTrip.
%
% If TANK is not specified, a list box will appear with registered tanks.
%
% If BLOCK is not specified, a list box will appear with blocks of the tank.
%
% BLOCKROOT can be specified if the blocks begin with something other than
% 'Block-' (must include '-' if it's there).
%
% The event to which the data should be organized is determined either by
% EVENTNAME (if specified) or a single event name from the tank.  If
% EVENTNAME is not specified and there is more than one event found in the
% tank, then a prompt will appear for the user to select the correct event.
% 
% See also, ft_read_event, TankReg
%
% DJS 2013


% check inputs
if nargin == 0 || isempty(tank),  tank = char(TDT_TankSelect); end
cfg.tank     = tank;
cfg.datatype = 'BlockInfo';
cfg.usemym   = false;
if nargin < 2
    tinfo = getTankData(cfg);
    if isempty(tinfo)
        error('No blocks found in ''%s''',tank)
    end
    [sel,ok] = listdlg('PromptSstring','Select one block', ...
                       'SelectionMode','single', ...
                       'ListString',num2cell([tinfo.block]));
    if ~ok, return; end
    block = tinfo(sel).block;
end
if nargin < 3 || isempty(blockroot), blockroot = 'Block-'; end

% get tank info
cfg.blocks      = block;
cfg.blockroot   = blockroot;
cfg.datatype    = 'BlockInfo';
cfg.usemym      = false;
tinfo           = getTankData(cfg);

% because LFP data would have been downsampled (make user defined parameter)
Fs = min(tinfo.allfsamples);
if Fs > 1500
    Fs = Fs/round(Fs/1000);
end

% deal with event name
selparam = 1; % default
params = tinfo.paramspec(1:end-1); % last parameter is always onsets of trigger
if nargin == 4 && ~isempty(eventname) % eventname was specified by user
    selparam = strcmpi(eventname,params);
    if isempty(selparam)
        error('No events called ''%s'' were found in tank ''%s''',eventname,tank);
    end
    
else % eventname was not specified
    if length(params) > 2 % meaning more than one parameter + onsets of trigger
        [selparam,ok] = listdlg('ListString',params(1:end-1), ...
                           'Name','Read Event TDT', ...
                           'PromptString','Select one event from the list:', ...
                           'SelectionMode','single');
        if ~ok
            disp('User cancelled event selection.')
            return
        end
    end
end
parind = strcmpi(params{selparam},params);

% generate event structure
rvalues = tinfo.epochs(:,parind);
ronsets = tinfo.epochs(:,end);
ronsamp = round(ronsets*Fs);
event = [];
for j = 1:length(rvalues)
    event(j).type       = params{selparam}; %#ok<AGROW>
    event(j).sample     = ronsamp(j); %#ok<AGROW>
    event(j).value      = rvalues(j); %#ok<AGROW>
    event(j).timestamp  = ronsets(j); %#ok<AGROW>
end










