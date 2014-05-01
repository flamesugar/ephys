function [data] = SEV2mat(varargin)
%SEV2MAT  TDT SEV file format extraction.
%   data = SEV2mat(SEV_DIR), where SEV_DIR is a string, retrieves
%   all sev data from specified directory in struct format. SEV files
%   are generated by an RS4 Data Streamer, or by setting the Unique
%   Channel Files option in Stream_Store_MC or Stream_Store_MC2 macro
%   to Yes.
%
%   data    contains all continuous data (sampling rate and raw data)
%
%   data = SEV2mat(SEV_DIR, JUSTNAMES), where JUSTNAMES is a boolean, 
%   returns the event names stored in the SEV files.
%
%   data = SEV2mat(SEV_DIR, EVENTNAME), where EVENTNAME is a string,
%   returns the sev data from specified event name.
%
%   data = SEV2mat(DEVICE, TANK, BLOCK), where DEVICE, TANK and BLOCK are
%   strings, retrieves all sev data from specified device, tank and block.
%   DEVICE can be IP address or NetBIOS name of RS4 device (e.g. RS4-41001)

data = [];

ALLOWED_FORMATS = {'single','int32','int16','int8','double','int64'};
MAP = containers.Map(...
    0:length(ALLOWED_FORMATS)-1,...
    ALLOWED_FORMATS);
    
numvarargs = length(varargin);
if numvarargs < 1 || numvarargs > 3
    error('requires 1 to 3 inputs');
end

bJustNames = 0;
specificEvent = '';
if numvarargs == 1
    sev_dir = varargin{:};
elseif numvarargs == 2
    [sev_dir, var2] = varargin{:};
    if isnumeric(var2)
        bJustNames = var2;
    else
        specificEvent = var2;
    end        
elseif numvarargs == 3
    [device, tank, block] = varargin{:};
    sev_dir = sprintf('\\\\%s\\data\\%s\\%s\\', device, tank, block);
end

eventNames = {};
eventNameCount = 0;

if strcmp(sev_dir(end), '\') == 0
    sev_dir = [sev_dir '\'];
end

file_list = dir([sev_dir '*.sev']);
if length(file_list) < 1
    warning(['no sev files found in ' sev_dir])
    return
end

for i = 1:length(file_list)
    path = [sev_dir file_list(i).name];
    
    % open file
    fid = fopen(path, 'rb');
    
    if fid < 0
        warning([path ' not opened'])
        return
    end
    
    % create and fill streamHeader struct
    streamHeader = [];
    
    streamHeader.fileSizeBytes   = fread(fid,1,'uint64');
    streamHeader.fileType        = char(fread(fid,3,'char')');
    streamHeader.fileVersion     = fread(fid,1,'char');
    
    if streamHeader.fileVersion < 3
        
        % event name of stream
        if streamHeader.fileVersion == 2 
            streamHeader.eventName  = char(fread(fid,4,'char')');
        else
            streamHeader.eventName  = fliplr(char(fread(fid,4,'char')'));
        end
        
        % current channel of stream
        streamHeader.channelNum        = fread(fid, 1, 'uint16');
        % total number of channels in the stream
        streamHeader.totalNumChannels  = fread(fid, 1, 'uint16');
        % number of bytes per sample
        streamHeader.sampleWidthBytes  = fread(fid, 1, 'uint16');
        reserved                 = fread(fid, 1, 'uint16');
        
        % data format of stream in lower four bits
        streamHeader.dForm      = MAP(bitand(fread(fid, 1, 'uint8'),7));
        
        % used to compute actual sampling rate
        streamHeader.decimate   = fread(fid, 1, 'uint8');
        streamHeader.rate       = fread(fid, 1, 'uint16');
        
        % reserved tags
        reserved = fread(fid, 1, 'uint64');
        reserved = fread(fid, 2, 'uint16');
        
    end
    
    if streamHeader.fileVersion > 0
        % determine data sampling rate
        streamHeader.Fs = 2^(streamHeader.rate)*25000000/2^12/streamHeader.decimate;
        % handle multiple data streams in one folder
        eval(sprintf('exists = isfield(data,''%s'');', ...
            streamHeader.eventName))
    else
        streamHeader.dForm = 'single';
        streamHeader.Fs = 0;
        s = regexp(file_list(i).name, '_', 'split');
        streamHeader.eventName = s{3};
        streamHeader.channelNum = str2double(regexp(s{4},  '\d+', 'match'));
        warning(sprintf('%s has empty header; assuming %s ch %d format %s\nupgrade to OpenEx v2.18 or above\n', ...
            file_list(i).name, streamHeader.eventName, ...
            streamHeader.channelNum, streamHeader.dForm));
        
        exists = 1;
        eval(sprintf('data.%s.fs = %f;', streamHeader.eventName, ...
            streamHeader.Fs));
    end

    % skip if this isn't exactly what we're looking for
    if ~strcmp(specificEvent, '') && ~strcmp(specificEvent, streamHeader.eventName)
        fclose(fid);
        continue
    end
    
    % read rest of file into data array as correct format
    
    if bJustNames
        bFoundIt = 0;
        for name = 1:length(eventNames)
            bFoundIt = strcmp(eventNames{name}, streamHeader.eventName);
        end
        if bFoundIt == 0
            eventNameCount = eventNameCount + 1;
            eventNames{eventNameCount} = streamHeader.eventName;
        end
    else
        eval(sprintf('data.%s.name = ''%s'';', streamHeader.eventName, ...
            streamHeader.eventName));
        if exists ~= 1
            %preallocate data array
            temp_data = fread(fid, inf, ['*' streamHeader.dForm])';
            total_samples = length(temp_data);
            eval(sprintf('data.%s.data = %s(zeros(%d,%d));', ...
                streamHeader.eventName, ...
                streamHeader.dForm, ...
                streamHeader.totalNumChannels, ...
                total_samples));
            eval(sprintf('data.%s.data(%d,:) = temp_data;', ...
                streamHeader.eventName, ...
                streamHeader.channelNum));
            eval(sprintf('data.%s.fs = %f;', ...
                streamHeader.eventName, ...
                streamHeader.Fs));
        else
            eval(sprintf('data.%s.data(%d,:) = fread(fid, inf, ''*%s'')'';', ...
                streamHeader.eventName, ...
                streamHeader.channelNum, ...
                streamHeader.dForm));
        end
    end
    
    % close file
    fclose(fid);
    
    %if streamHeader.fileVersion > 0
    %    % verify streamHeader is 40 bytes
    %    dataSize = length(streamData) * streamHeader.sampleWidthBytes;
    %    streamHeaderSizeBytes = streamHeader.fileSizeBytes - dataSize;
    %    if streamHeaderSizeBytes ~= 40
    %        warning('streamHeader Size Mismatch -- %d bytes vs 40 bytes', streamHeaderSizeBytes);
    %    end
    %end
end

streamHeader
if bJustNames, data = eventNames; end
end

