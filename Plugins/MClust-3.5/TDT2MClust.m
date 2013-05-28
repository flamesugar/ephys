function TDT2MClust(tank,blocks,channels,targdir)
% TDT2MClust(tank)
% TDT2MClust(tank,blocks)
% TDT2MClust(tank,blocks,channels)
% TDT2MClust(tank,blocks,channels,targdir)
% 
% DJS 2013


if nargin == 1 || ~exist('blocks','var') || isempty(blocks)
    % do all blocks
    blocks = TDT2mat(tank,[],'silent',true);
elseif isnumeric(blocks)
    nblocks = blocks;
    blocks = cell(size(nblocks));
    for i = 1:length(nblocks)
        blocks{i} = sprintf('Block-%d',nblocks(i));
    end
end
nblocks = cellfun(@(x) str2num(x(find(x=='-',1,'last')+1:end)),blocks); %#ok<ST2NM>

if nargin < 4 || ~exist('targdir','var') || isempty(targdir)
    targdir = cd;
end

for i = 1:length(blocks)
    data(i) = TDT2mat(tank,blocks{i},'silent',true,'type',3); %#ok<AGROW>
end


SNIP = char(fieldnames(data(1).snips));

for i = 1:length(data)
    if nargin < 3 || ~exist('channels','var') || isempty(channels)
        channels = unique(unique(data(i).snips.eNeu.chan));
    end
    for c = channels
        if i == 1, 
            spikes{c}.spiketimes = []; %#ok<AGROW>
            spikes{c}.waveforms  = []; %#ok<AGROW>
            spikes{c}.unwrapped_times = []; %#ok<AGROW>
            spikes{c}.unwrapped_blocks = []; %#ok<AGROW>
            spikes{c}.validblocks = []; %#ok<AGROW>
            spikes{c}.channel = c; %#ok<AGROW>
        end
            
        cind = data(i).snips.(SNIP).chan == c;
        n  = sum(cind);
        ts = data(i).snips.(SNIP).ts(cind);
        wf = data(i).snips.(SNIP).data(cind,:);
        
        if isempty(ts), continue; end
        
        spikes{c}.spiketimes(end+1:end+n,1)  = ts; %#ok<AGROW>
        spikes{c}.unwrapped_blocks(end+1:end+n,1) = nblocks(i)*ones(n,1); %#ok<AGROW>
        
        if ndims(wf) == 2 %#ok<ISMAT>
            [n1, n2] = size(wf);
            wf = [reshape(wf,[n1 1 n2]) zeros(n1,3,n2)];
        end
        spikes{c}.waveforms(end+1:end+n,1:4,:) = wf; %#ok<AGROW>
        
        if i > 1
            ts = ts + spikes{c}.unwrapped_times(end) + 60; % add 60 seconds between trials
        end
        spikes{c}.unwrapped_times(end+1:end+n,1) = ts; %#ok<AGROW>
        spikes{c}.validblocks(end+1) = nblocks(i); %#ok<AGROW>
    end
end

for i = 1:length(spikes)
    data = spikes{i};
    if isempty(data), continue; end
    bstr = num2str(data.validblocks,'%d-'); bstr(end) = [];
    fn = sprintf('%s_[%s]-%d.dat',tank,bstr,data.channel);
    fprintf('\tSaving: ''%s''\t% 8.0f spikes\t...',fn,length(data.spiketimes))
    save(fullfile(targdir,fn),'data','-mat');
    fprintf(' done\n')
end











