function RF_FreqVsTime(unit_id)
% RF_FreqVsTime
% RF_FreqVsTime(unit_id)
% 
% Visualize receptive field as frequency vs time raster
%
% daniel.stolzberg@gmail.com 2013
if nargin == 0 || isempty(unit_id)
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end

f = findobj('tag','RF_FreqVsTime');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'tag','RF_FreqVsTime');
end

h.unit_id = unit_id;
h.f  = f;
guidata(h.f,h);

h = init([],[],f);
guidata(h.f,h);


function h = init(~,~,f)
h = guidata(f);
figure(h.f);
clf(h.f);
set(h.f,'Name',sprintf('Unit ID: %d',h.unit_id),'units','normalized');

h.RF.P = DB_GetParams(h.unit_id,'unit');
h.RF.st = DB_GetSpiketimes(h.unit_id);

h.dBprops = DB_GetUnitProps(h.unit_id,'RFid01');

guidata(h.f,h);

h = creategui(h.f);

UpdateFig(h.LevelList,'init',h.f)


function h = creategui(f)
h = guidata(f);

h.f = f;

set(f,'CloseRequestFcn',@CloseMe);

rfwin = [0 50]; % receptive field plot
rwin  = [0 150]; % raster plot

L = h.RF.P.lists.Levl;
level = max(L);

opts = getpref('RF_FreqVsTime',{'rfwin','rwin','level','windowpos'},{rfwin,rwin,level,[]});

rfwin = opts{1};
rwin  = opts{2};
level = opts{3};

if ~isempty(opts{4}) && length(opts{4}) == 4
    set(f,'position',opts{4});
end

ind = level == L;
if ~any(ind), ind = L == max(L); end
h.LevelList = uicontrol(f,'Style','popup','String',L,'Value',find(ind), ...
    'units','normalized','Position',[0.3 0.86 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','LevelList');
fbc = get(f,'Color');
uicontrol(f,'Style','text','String','Level (dB):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.86 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


h.rwin = uicontrol(f,'Style','edit','String',mat2str(rwin), ...
    'units','normalized','Position',[0.3 0.80 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','rwin');
uicontrol(f,'Style','text','String','Raster Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.80 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


h.rfwin = uicontrol(f,'Style','edit','String',mat2str(rfwin), ...
    'units','normalized','Position',[0.3 0.74 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','rfwin');
uicontrol(f,'Style','text','String','RF Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.74 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);

guidata(f,h);


function CloseMe(hObj,~)
h = guidata(hObj);
pos = get(h.f,'Position');
setpref('RF_FreqVsTime','windowpos',pos);
delete(h.f);


function UpdateFig(hObj,event,f) %#ok<INUSL>
h = guidata(f);

s = cellstr(get(h.LevelList,'String'));
level = str2num(s{get(h.LevelList,'Value')}); %#ok<ST2NM>
rwin  = str2num(get(h.rwin,'String')); %#ok<ST2NM>
rfwin = str2num(get(h.rfwin,'String')); %#ok<ST2NM>

% receptive field
subplot(3,5,[4 5],'replace')
[rfdata,rfvals] = shapedata_spikes(h.RF.st,h.RF.P,{'Freq','Levl'}, ...
    'win',rfwin/1000,'binsize',0.001,'func','sum');
plotrf(rfdata*1000,rfvals);
hold on
set(gca,'clipping','off');
x = xlim(gca);
z = zlim(gca);
po = patch([x fliplr(x)],ones(1,4)*level,[z(1) z(1) z(2) z(2)]);
set(po,'zdata',[z(1) z(1) z(2) z(2)],'facecolor','w','facealpha',0.5, ...
    'edgecolor','w','edgealpha',0.5)
plotrffeatures(gca,h.dBprops);
hold off
    
% raster
subplot(3,5,[6 14],'replace')
rast = genrast(h.RF.st,h.RF.P,level,rwin/1000);
plotraster(h.RF.P,rast,rwin,rfwin,level);
hold on
plotrasterfeatures(gca,h.dBprops,level);
plot([0 0],ylim,'-','color',[0.6 0.6 0.6]);
hold off

% histogram
rfdata = shapedata_spikes(h.RF.st,h.RF.P,{'Freq','Levl'}, ...
    'win',[-0.05 0],'binsize',0.001,'func','sum');
spontrate = mean(rfdata(:));
plothist(rast,h.RF.P.lists.Freq,rfwin,spontrate);
hold on
plotrasterfeatures(gca,h.dBprops,level);
hold off

setpref('RF_FreqVsTime',{'rfwin','rwin','level'},{rfwin,rwin,level});


function plothist(rast,Freq,win,spontrate)
subplot(3,5,[10 15]);
f = Freq / 1000;
nfreqs = length(f);
nreps = length(rast) / length(f);

win = win / 1000;

trast = cellfun(@(x) (x(x>=win(1) & x < win(2))),rast,'UniformOutput',false);
cnt = cellfun(@numel,trast);
cnt = reshape(cnt,nreps,nfreqs);
h = mean(cnt);
ch = conv(h,gausswin(5),'same');
ch = ch / max(ch) * max(h);


plot(ch,f,'-','linewidth',2,'color',[0.4 0.4 0.4]);
hold on
b = barh(f,h,'hist');
delete(findobj(gca,'marker','*'));
set(b,'facecolor',[0.8 0.94 1],'edgecolor','none');
set(gca,'yscale','log','ylim',[f(1) f(end)],'yaxislocation','right', ...
    'ytick',[1 5 10 50],'yticklabel',[1 5 10 50])
plot([1 1]*spontrate,ylim,'-','color',[0.5 0.5 0.5])
hold off

xlabel('Mean spike count','fontsize',8);

function plotrf(data,vals)
%% Plot Receptive Field
x = vals{2};
y = vals{3};

data = squeeze(mean(data));
data = sgsmooth2d(data);
data = interp2(data,3,'cubic');

ny = length(y);
nx = length(x);
x = interp1(logspace(log10(1),log10(nx),nx),x,logspace(log10(1),log10(nx),size(data,1)),'pchip');
y = interp1(y,linspace(1,ny,size(data,2)),'linear');

hax = surf(x/1000,y,data');
shading flat
view(2)
axis tight
md = max(data(:));
if isnan(md) || md == 0, md = 1; end
set(gca,'xscale','log','fontsize',7,'xtick',[1 5 10 50],'xticklabel',[1 5 10 50], ...
    'zlim',[0 md])
set(hax,'ButtonDownFcn',{@clickrf,gcf});
xlabel('Frequency (kHz)','fontsize',7)
ylabel('Level (dB)','fontsize',7)
h = colorbar('EastOutside','fontsize',7);
c = get(gca,'clim');
set(gca,'clim',[0 c(2)]);
ylabel(h,'Firing Rate (Hz)','fontsize',7)


function clickrf(hObj,event,f) %#ok<INUSL>
h = guidata(hObj);
cp = get(gca,'CurrentPoint');
level = cp(1,2);
L = str2num(get(h.LevelList,'String')); %#ok<ST2NM>
i = interp1(L,1:length(L),level,'nearest');
if isempty(i) || isnan(i), return; end
set(h.LevelList,'Value',i);
UpdateFig(h.LevelList,'clickrf',f)

function rast = genrast(st,P,level,win)
ind  = P.VALS.Levl == level;
ons  = P.VALS.onset(ind);
wons = ons + win(1);
wofs = ons + win(2);
rast = cell(size(ons));
for i = 1:length(ons)
    sind = st >= wons(i) & st <= wofs(i);
    rast{i} = st(sind) - ons(i);
end
f = P.VALS.Freq(ind);
[~,i] = sort(f);
rast = rast(i);

function plotraster(P,rast,win,respwin,level)
rast = cellfun(@(a) (a*1000),rast,'UniformOutput',false); % s -> ms
nreps = sum(P.VALS.Freq == P.lists.Freq(end) & P.VALS.Levl == level);
f = P.lists.Freq / 1000;
f = interp1(1:length(f),f,linspace(1,length(f),length(f)*nreps),'cubic');

minf = min(f);
maxf = max(f);
patch([respwin fliplr(respwin)],[minf minf maxf maxf],[0.8 0.94 1], ...
    'EdgeColor','none');


hold on
for i = 1:length(rast)
    if isempty(rast{i}), continue; end
    plot(rast{i},f(i),'sk');
end
hold off
set(get(gca,'children'),'markersize',2,'markerfacecolor','k');
set(gca,'yscale','log','ylim',[min(P.lists.Freq) max(P.lists.Freq)]/1000, ...
    'ytick',[1 5 10 50],'yticklabel',[1 5 10 50],'xlim',win, ...
    'tickdir','out');
box on
xlabel('Time (ms)','FontSize',9);
ylabel('Frequency (kHz)','FontSize',9);
title(sprintf('%d dB',level),'FontSize',14);
    
    
    
function plotrasterfeatures(ax,p,level)
if isempty(p), return; end

x = xlim(ax);

y = 0:5:100;

flevel = round(level - p.minthresh);
flevel = interp1(y,y,flevel,'nearest');
LowFreq  = sprintf('LowFreq%02ddB',flevel);
HighFreq = sprintf('HighFreq%02ddB',flevel);

mlevel = interp1(y,y,p.minthresh,'nearest');
if isnan(mlevel), mlevel = 0; end

set(ax,'clipping','off')

fn = fieldnames(p)';
for f = fn
    f = char(f); %#ok<FXSET>
    switch f
        case 'bestfreq'
        
        case 'charfreq'
            if level ~= mlevel, continue; end
            plot(ax,x,[1 1]*p.charfreq/1000,'-r');
            plot(ax,x(1),p.charfreq/1000,'>r','markerfacecolor','r');
            plot(ax,x(2),p.charfreq/1000,'<r','markerfacecolor','r');
                    
        case LowFreq
            plot(ax,x,[1 1]*p.(f)/1000,'-^','color',[0.57 0.57 0.98], ...
                'markerfacecolor',[0.57 0.57 0.98]);
            
        case HighFreq
            plot(ax,x,[1 1]*p.(f)/1000,'-v','color',[0.98 0.57 0.57], ...
                'markerfacecolor',[0.98 0.57 0.57]);
    end    
end


function plotrffeatures(ax,p)
if isempty(p), return; end

set(ax,'clipping','off')

z = get(ax,'zlim');

if ~all(isfield(p,{'charfreq','minthresh'})), return; end

plot3(ax,[1 1]*p.charfreq/1000,[1 1]*round(p.minthresh),z,'^-r', ...
    'markerfacecolor','r','markersize',4);






    
    
    
    
    
    
    
    
    
    
    

