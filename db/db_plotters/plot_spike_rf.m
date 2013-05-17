function plot_spike_rf(pref,P,param,cfg)
% plot_spike_rf(pref,P,param,cfg)
% 
% For use with DB_QuickPlot
%
% DJS 2013

% get spike times of selected unit
S = DB_GetSpiketimes(pref.units);

win = [cfg.win_on cfg.win_off] / 1000; % ms -> s

% Organize by stimulus onsets
ons = P.VALS.onset;

TS = cell(size(ons));
for i = 1:length(ons)
    ind = S >= ons(i) + win(1) & S < ons(i) + win(2);
    TS{i} = S(ind) - ons(i);
end

% Reorganize by stimulus type
for i = 1:length(param)
    stims{i} = P.lists.(param{i}); %#ok<AGROW>
end
RFraster = cell(numel(stims{1}),numel(stims{2}));
for i = 1:numel(stims{1})
    for j = 1:numel(stims{2})
        ind = P.VALS.(param{1}) == stims{1}(i) ... 
            & P.VALS.(param{2}) == stims{2}(j);
        
        RFraster{i,j} = cell2mat(TS(ind));
        
    end
end
RFcnt = cellfun(@numel,RFraster,'UniformOutput',true)';


% post processing based on user options
if cfg.smooth2d, RFcnt = sgsmooth2d(RFcnt); end
if cfg.interpolate > 1
    RFcnt = interp2(RFcnt,cfg.interpolate);
    if cfg.xislog
        stims{1} = logspace(log10(stims{1}(1)),log10(stims{1}(end)),size(RFcnt,2));
    else
        stims{1} = linspace(stims{1}(1),stims{1}(end),size(RFcnt,2));
    end
    stims{2} = linspace(stims{2}(1),stims{2}(end),size(RFcnt,1));
end

set(gcf,'renderer','zbuffer'); % OpenGL doesn't seem to like log axes

surf(stims{1},stims{2},RFcnt);
view(2)
if cfg.interpolate > 1 || cfg.smooth2d
    shading interp
else
    shading flat
end
if cfg.xislog, set(gca,'xscale','log'); end
axis tight










