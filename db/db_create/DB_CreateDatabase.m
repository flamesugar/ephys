function DB_CreateDatabase(name)
% DB_CreateDatabase(name)
% 
% Use to create all tables for a new database with the name of the input
% parameter NAME.
% 
% DJS 2013

dbs = dblist;

if any(strcmpi(dbs,name))
%     fprintf(['A database called "%s" already exists on the server ', ...
%              '... rebuilding tables\n'],name)
else
    dbadd(name);
    fprintf('''%s'' database created ... building tables\n',name)
end

dbopen(name);

%% dbinfo table
mym(['CREATE TABLE IF NOT EXISTS dbinfo (' ...
     'infotype   VARCHAR(50), ', ...
     'infostr    tinytext ', ...
     ') ENGINE = MyISAM']);


%% experiments table
mym(['CREATE TABLE IF NOT EXISTS experiments (' ...
    'id             smallint        UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'name           char(25)        NOT NULL, ' ...
    'subject_id     smallint        UNSIGNED, ' ...
    'start_date     date, ' ...
    'end_date       date, ' ...
    'researcher     varchar(25), ' ...
    'in_use         boolean         DEFAULT TRUE, ' ...
    'PRIMARY KEY (id) ' ...
    ') ENGINE=MyISAM']);

%% subjects table
mym(['CREATE TABLE IF NOT EXISTS subjects (' ...
    'id             tinyint         UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'name           char(25)        NOT NULL, ' ...
    'alias          char(25), ' ...
    'species        char(15)        NOT NULL, ' ...
    'strain         char(25), ' ...
    'dob            date, ' ...
    'weight         float           UNSIGNED, ' ...
    'sex            char(1), ' ...
    'subject_notes  mediumtext, ' ...
    'PRIMARY KEY (id) ' ...
    ') ENGINE=MyISAM']);

%% treatments table
mym(['CREATE TABLE IF NOT EXISTS treatments (' ...
    'id             smallint        UNSIGNED NOT NULL AUTO_INCREMENT, ', ...
    'treatment_id   tinyint         UNSIGNED NOT NULL, ' ...
    'subject_id     smallint        UNSIGNED NOT NULL, ' ...
    'treatment      varchar(100), ' ...
    'dose           float, ' ...
    'route          tinyint         UNSIGNED, ' ...
    'treatment_date date, ' ...
    'treatment_time time, ' ...
    'PRIMARY KEY (id) ' ...
    ') ENGINE=MyISAM']);

%% tanks table
mym(['CREATE TABLE IF NOT EXISTS tanks (' ...
    'id             smallint        UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'exp_id         smallint        UNSIGNED NOT NULL, ' ...
    'tank_condition varchar(30), ' ...
    'name           varchar(25)     NOT NULL UNIQUE, ' ...
    'in_use         boolean         DEFAULT TRUE, ' ...
    'tank_date      date, ' ...
    'tank_time      time, ' ...
    'spike_fs       float(12,6), ' ...
    'wave_fs        float(12,6), ' ...
    'tank_notes     mediumtext, ' ...
    'PRIMARY KEY (id) ' ...
    ') ENGINE=MyISAM']);


%% electrodes table
mym(['CREATE TABLE IF NOT EXISTS electrodes (' ...
    'id             smallint        UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'tank_id        smallint        UNSIGNED NOT NULL UNIQUE, ' ...
    'type           smallint        UNSIGNED, ' ...
    'depth          float, ' ...
    'target         varchar(10), ' ...
    'PRIMARY KEY (id) ' ...
    ') ENGINE=MyISAM']);

%% blocks table
mym(['CREATE TABLE IF NOT EXISTS blocks (' ...
    'id             smallint        UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'tank_id        smallint        UNSIGNED NOT NULL, ' ...
    'block          tinyint         UNSIGNED NOT NULL, ' ...
    'protocol       smallint        UNSIGNED NOT NULL, ' ...
    'in_use         boolean         DEFAULT TRUE, ' ...
    'block_date     date, ' ...
    'block_time     time, ' ...
    'block_notes    mediumtext, ' ...
    'PRIMARY KEY (id) ' ...
    ') ENGINE=MyISAM']);


%% protocols table
mym(['CREATE TABLE IF NOT EXISTS protocols (' ...
    'id             bigint          UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'block_id       smallint        UNSIGNED NOT NULL, ' ...
    'param_id       mediumint       UNSIGNED NOT NULL, ' ...
    'param_type     tinyint         UNSIGNED NOT NULL, ' ...
    'param_value    float           NOT NULL, ' ...
    'PRIMARY KEY (block_id,id)) ENGINE=MyISAM ' ...
    'PARTITION BY LIST (block_id % 10) ( ' ...
    '   PARTITION p0 VALUES IN (0), ' ...
    '   PARTITION p1 VALUES IN (1), ' ...
    '   PARTITION p2 VALUES IN (2), ' ...
    '   PARTITION p3 VALUES IN (3), ' ...
    '   PARTITION p4 VALUES IN (4), ' ...
    '   PARTITION p5 VALUES IN (5), ' ...
    '   PARTITION p6 VALUES IN (6), ' ...
    '   PARTITION p7 VALUES IN (7), ' ...
    '   PARTITION p8 VALUES IN (8), ' ...
    '   PARTITION p9 VALUES IN (9))']);


%% channels table
mym(['CREATE TABLE IF NOT EXISTS channels (' ...
    'id             int             UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'block_id       smallint        UNSIGNED NOT NULL, ' ...
    'channel        int(3)          ZEROFILL UNSIGNED NOT NULL, ' ...
    'target         char(4)         DEFAULT " ", ' ...
    'in_use         boolean         DEFAULT TRUE, ' ...    
    'PRIMARY KEY (id) ' ...
    ') ENGINE=MyISAM']);

%% spike_data table
mym(['CREATE TABLE IF NOT EXISTS spike_data (' ...
    'id             int             UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'unit_id        int             UNSIGNED NOT NULL, ' ...
    'spike_time     float(11,6)     NOT NULL, ' ...
    'PRIMARY KEY (unit_id,id)) ENGINE=MyISAM ' ...
    'PARTITION BY LIST (unit_id % 10) ( ' ...
    '   PARTITION p0 VALUES IN (0), ' ...
    '   PARTITION p1 VALUES IN (1), ' ...
    '   PARTITION p2 VALUES IN (2), ' ...
    '   PARTITION p3 VALUES IN (3), ' ...
    '   PARTITION p4 VALUES IN (4), ' ...
    '   PARTITION p5 VALUES IN (5), ' ...
    '   PARTITION p6 VALUES IN (6), ' ...
    '   PARTITION p7 VALUES IN (7), ' ...
    '   PARTITION p8 VALUES IN (8), ' ...
    '   PARTITION p9 VALUES IN (9))']);

%% wave_data table
mym(['CREATE TABLE IF NOT EXISTS wave_data (' ...
    'channel_id     int             UNSIGNED NOT NULL, ' ...
    'param_id       mediumint(8)    UNSIGNED NOT NULL, ' ...
    'waveform       blob, ' ...
    'PRIMARY KEY (channel_id,param_id)) ENGINE=MyISAM ' ...
    'PARTITION BY LIST (channel_id % 10) ( ' ...
    '   PARTITION p0 VALUES IN (0), ' ...
    '   PARTITION p1 VALUES IN (1), ' ...
    '   PARTITION p2 VALUES IN (2), ' ...
    '   PARTITION p3 VALUES IN (3), ' ...
    '   PARTITION p4 VALUES IN (4), ' ...
    '   PARTITION p5 VALUES IN (5), ' ...
    '   PARTITION p6 VALUES IN (6), ' ...
    '   PARTITION p7 VALUES IN (7), ' ...
    '   PARTITION p8 VALUES IN (8), ' ...
    '   PARTITION p9 VALUES IN (9))']);
    
   
%% units table
mym(['CREATE TABLE IF NOT EXISTS units (' ...
    'id             int             UNSIGNED NOT NULL AUTO_INCREMENT, ' ...
    'channel_id     int             UNSIGNED NOT NULL, ' ...
    'pool           tinyint         UNSIGNED DEFAULT 5, ' ...
    'note           char(150), ' ...
    'unit_count     int             UNSIGNED, ' ...
    'pool_waveform  text, ' ...
    'pool_stddev    text, ' ...
    'in_use         boolean         DEFAULT TRUE, ' ...    
    'isbad          boolean         DEFAULT FALSE, ' ...
    'PRIMARY KEY (id)) ENGINE=MyISAM']);

%% dbinfo table
mym(['CREATE TABLE IF NOT EXISTS dbinfo (' ...
    'infotype       varchar(50)     NOT NULL, ' ...
    'infostr        tinytext, ' ...
    'PRIMARY KEY (infotype)) ENGINE=MyISAM']);

%% analysis settings
mym(['CREATE TABLE IF NOT EXISTS analysis_settings (' ...
     'id        TINYINT  UNSIGNED NOT NULL, ' ...
     'avalue    TINYBLOB NOT NULL, ' ...
     'PRIMARY KEY (id)) ENGINE = MyISAM']);
 
%% create view for table ids
try %#ok<TRYNC>
    mym(['CREATE VIEW v_ids AS ', ...
        'select ', ...
        'e.id AS experiment,', ...
        't.id AS tank,', ...
        'b.id AS block,', ...
        'c.id AS channel,', ...
        'u.id AS unit', ...
        'from experiments e ', ...
        'join tanks t ON e.id = t.exp_id ', ...
        'join blocks b ON t.id = b.tank_id ', ...
        'join channels c ON b.id = c.block_id ', ...
        'join units u ON c.id = u.channel_id']);
end

DB_CreateUnitPropertiesTable;

