function DB_UpdateUnitProps(unit_id,P,groupid,verbose)
% DB_UpdateUnitProps(unit_id,P,groupid)
% DB_UpdateUnitProps(unit_id,P,groupid,verbose)
%
% Updates unit_properties table of currently selected database.
%
% Accepts a unit_id (from units table) and P which is a structure in which
% each field name is an existing name from db_util.analysis_params table.  
%
% Fields of P can be a matrix of any size/dimensions and either a cellstr
% type or numeric type.
%
% groupid is a string with the name of one field in the structure P.  This
% field (P.(groupid)) is used to group results in unit_properties by some 
% common value such as sound level, frequency, etc.  If P.(groupid) can
% also be numeric.
%
% ex: % this example uploads peakfr and peaklat with the group level
%   P.level   = {'10dB','30dB','50dB','70dB'};
%   P.peakfr  = [6.1, 10.3, 24.2, 56.1];
%   P.peaklat = [15.1, 14.0, 12.1, 11.5];
%   groupid = 'level';
%   DB_UpdateUnitProperties(unit_id,P,groupid)
% 
% If verbose is true, then the updating progress will be displayed in the
% command window. (default = false)
%
% See also, DB_GetUnitProps, DB_CheckAnalysisParams
% 
% DJS 2013 daniel.stolzberg@gmail.com

narginchk(3,4);

if nargin >= 3 && ~isfield(P,groupid)
    error('The groupid string must be a fieldname in structure P');
end

if nargin < 4, verbose = true; end

ap = mym('SELECT id, name FROM db_util.analysis_params');

fn = fieldnames(P)';
fn(ismember(fn,groupid)) = [];

if isnumeric(P.(groupid))
    P.(groupid) = num2str(P.(groupid)(:));
    P.(groupid) = cellstr(P.(groupid));
elseif ~iscellstr(P.(groupid))
    P.(groupid) = cellstr(P.(groupid));
end

fstrs = 'unit id %d\t%s: %s\t%s: %s\n';

% UNIT_ID, PARAM_ID,GROUP_ID,PARAMS,PARAMF
fstr = '%d,%d,"%s","%s","%s"\r\n';

fname = fullfile(cd,'DB_TMP.txt');
fid = fopen(fname,'w');

[pnames,pids] = myms('SELECT DISTINCT name,id FROM db_util.analysis_params');

dltstr = ['DELETE FROM unit_properties ', ...
          'WHERE unit_id = %d AND group_id = "%s" AND param_id = %d'];
for f = fn
    f = char(f); %#ok<FXSET>
    ind = ismember(pnames,f);
    p = pids(ind);
    for i = 1:numel(P.(groupid))
        mym(sprintf(dltstr,unit_id,P.(groupid){i},p));
    end
end


for f = fn
    f = char(f); %#ok<FXSET>
    paramid = ap.id(ismember(ap.name,f));
    if ischar(P.(f))
        P.(f) = cellstr(P.(f));
    elseif isnumeric(P.(f)) || islogical(P.(f))
        P.(f) = num2cell(P.(f));
    end
    
    for i = 1:numel(P.(groupid))

        
        if i > numel(P.(f)), continue; end
        
        if isnan(P.(f){i}), P.(f){i} = 'NULL'; end

        if isnumeric(P.(f){i}) || islogical(P.(f){i})
            paramS = 'NULL'; paramF = num2str(P.(f){i},'%0.6f');
            
        else
            paramS = P.(f){i}; paramF = 'NULL';
            
        end
        fprintf(fid,fstr,unit_id,paramid,P.(groupid){i},paramS,paramF);
        
        if verbose
            if ischar(P.(f){i})
                fprintf(fstrs,unit_id,groupid,P.(groupid){i},f,paramS)
            else
                fprintf(fstrs,unit_id,groupid,P.(groupid){i},f,paramF)
            end
        end

    end
    
end

fclose(fid);

% replace '\' with '\\'  ... there's gotta be a bette way to do this
dbfname = '';
i = strfind(fname,'\');
k = 1;
for j = 1:length(i)
    dbfname = [dbfname '\\',fname(k:i(j)-1)]; %#ok<AGROW>
    k = i(j)+1;
end
dbfname(1:2) = []; dbfname = [dbfname '\\'];
dbfname = fullfile(dbfname,'DB_TMP.txt');

fprintf('Updating ...')
mym(sprintf(['LOAD DATA LOCAL INFILE ''%s'' INTO TABLE unit_properties ', ...
    'FIELDS TERMINATED BY '','' OPTIONALLY ENCLOSED BY ''"''', ...
    'LINES TERMINATED BY ''\r\n''', ...
    '(unit_id,param_id,group_id,paramS,paramF)',],dbfname))
fprintf(' done\n')




