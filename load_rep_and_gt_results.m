
% Initial setup
addpath('/Users/f.cravogomes/Desktop/Cloned Repos/NBS_Calculator')
scriptDir = fileparts(mfilename('fullpath'));
cd(scriptDir);
vars = who;       % Get a list of all variable names in the workspace
vars(strcmp(vars, 'rep_data')) = [];  % Remove the variable you want to keep from the list
clear(vars{:});   % Clear all other variables
clc;

%% Get rep data
if ~exist('rep_data', 'var')
    rep_data = unite_results_from_directory();
else
    % disp('Data already loaded')
end

%% Get GT data
GtData = load_gt_data();


%% Load gt data location in rep data
rep_data_cell = fieldnames(rep_data);
for i_rdc = 1:length(rep_data_cell)
    rep_data_set_name = rep_data_cell{i_rdc};
    
    rep_data_set_test_cell = fieldnames(rep_data.(rep_data_set_name));
    for i_rdtc = 1:length(rep_data_set_test_cell)
        rep_data_set_test = rep_data_set_test_cell{i_rdtc};
        
        dummy = strsplit(rep_data_set_name, '_');
        data_set_name = dummy{2};
        data_set_type = dummy{3};
        
        gt_data_location = {strcat(data_set_name, '_', data_set_type), rep_data_set_test};

        rep_data.(rep_data_set_name).(rep_data_set_test).gt_location = gt_data_location;

    end
        
end





