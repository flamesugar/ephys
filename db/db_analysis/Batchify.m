function Batchify(analysisfcn)
global KILLBATCH
KILLBATCH = false;
%%
ids = getpref('DB_BROWSER_SELECTION',{'experiments','blocks'});

prot = myms(sprintf('SELECT protocol FROM blocks WHERE id = %d LIMIT 1',ids{2}));

units = myms(sprintf(['SELECT DISTINCT v.unit FROM v_ids v ', ...
                      'JOIN units u ON u.id = v.unit ', ...
                      'LEFT OUTER JOIN v_unit_props p ON p.unit_id = v.unit ', ...
                      'JOIN blocks b ON v.block = b.id ', ...
                      'JOIN db_util.protocol_types pt ON pt.pid = b.protocol ', ...
                      'WHERE v.experiment = %d ', ...
                      'AND u.pool > 0 and b.protocol = %d ', ...
                      'AND u.in_use = TRUE AND b.in_use = TRUE'],ids{1},prot));

nunits = length(units);

%%
rng(123,'twister'); % Important: do not change this seed value from 123
units = units(randperm(nunits));

%%
if ischar(analysisfcn)
    astr = analysisfcn;
else
    astr = func2str(analysisfcn);
end

groupid = sprintf('Expt%03d_%s_LASTIDX',ids{1},astr);

k = myms(sprintf(['SELECT paramF FROM unit_properties WHERE unit_id = 0 ', ...
    'AND group_id = "%s"'],groupid));

if isempty(k)
    k = 1;
    mym(sprintf(['INSERT unit_properties (unit_id,param_id,group_id,paramF) ', ...
        'VALUES (0,(SELECT id FROM db_util.analysis_params WHERE name = "INFO"),', ...
        '"%s",1)'],groupid));
end

kstr = {num2str(k,'%d')};

k = inputdlg(sprintf(['%s\n\nEnter the unit sequence number (1 to %d) ', ...
    'at which you would like to start: '],astr,nunits),'Batch Analysis',1,kstr);

if isempty(k), return; end

k = str2num(k{1}); %#ok<ST2NM>
DB_CheckAnalysisParams({'INFO'},{''},{''})
lidxstr = 'UPDATE unit_properties SET paramF = %d WHERE group_id = "%s"';

for u = k:nunits
    fprintf('Unit %d of %d\n',k,nunits)
    af = feval(analysisfcn,units(k));
    f = LaunchBatchGUI(af);
    set(f,'Name',sprintf('BATCH: Unit %d of %d',k,nunits));
    uiwait(af);
    myms(sprintf(lidxstr,k,groupid));
    if KILLBATCH, break; end %#ok<UNRCH>
    k = k + 1;
    fprintf('\n')
end

assignin('base','LASTUNITIDX',k)
s = repmat('*',1,50);
fprintf('\n%s\nLast Unit Index: %d\n%s\n',s,k,s)




function f = LaunchBatchGUI(af)
f = findobj('type','figure','-and','tag','Batchify');
if isempty(f)
    f = figure('tag','Batchify','name','BATCH','units','normalized', ...
        'toolbar','none','dockcontrols','off','menubar','none', ...
        'numbertitle','off','position',[0.25 0.67 0.2 0.05]);
    
    
    uicontrol(f,'Style','pushbutton','String','Quit Batch', ...
        'units','normalized','Position',[0.05 0.05 0.5 0.9], ...
        'Tag','Quit','Fontsize',16);
    
    uicontrol(f,'Style','pushbutton','String','Next >', ...
        'units','normalized','Position',[0.55 0.05 0.4 0.9], ...
        'Tag','Next','Fontsize',16);    
end

set(f,'CloseRequestFcn',{@KillBatch,f,af});

set(findobj(f,'Tag','Quit'),'Callback',{@KillBatch,f,af});
set(findobj(f,'Tag','Next'),'Callback',{@NextUnit,af});

winontop(f);



function KillBatch(~,~,f,af)
global KILLBATCH

KILLBATCH = true;

uiresume(af);

delete(f);


function NextUnit(~,~,af)
delete(af);
