%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Setup for running NBS benchmarking
% This will load data and set up the parameters needed to run NBS benchmarking
% should be able to run config file, load rep_params and UI from reference, and replicate reference results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

%% Set paths, params, packages

% set paths and params
setpaths;
setparams;
addpath(genpath(nbs_dir));
addpath(genpath(other_scripts_dir));
subIDs_suffix='_subIDs.txt'; % TODO: move elsewhere

% octave stuff
page_screen_output (0); % for octave - also switched fprintf->printf
pkg load struct
pkg load parallel
pkg load ndpar


%% Compare subject IDs
% thanks https://www.mathworks.com/matlabcentral/answers/358722-how-to-compare-words-from-two-text-files-and-get-output-as-number-of-matching-words

% get non-task IDs
non_task_IDs_file=[data_dir,non_task_condition,subIDs_suffix];
non_task_IDs=fileread(non_task_IDs_file);
non_task_IDs=strsplit(non_task_IDs,'\n'); % octave

% get task IDs
if do_TPR
    
	% get task IDs
	task_IDs_file=[data_dir,task_condition,subIDs_suffix];
	task_IDs=fileread(task_IDs_file);
	task_IDs=strsplit(task_IDs,'\n'); % octave

	% compare w non-task
	fprintf(['Comparing subject IDs from from task (',task_IDs_file,') with IDs from non-task (',non_task_IDs_file,').\n']);
	[subIDs,~,~]=intersect(task_IDs,non_task_IDs);
	subIDs=subIDs(2:end); % bc the first find is empty - TODO add a check here first

else
	subIDs=non_task_IDs;
end

if testing
    n_subs=40;
    fprintf('** TESTING: Only using %d subjects to represent "full" data.\n',n_subs);
else
    n_subs=length(subIDs);
end




%% Load data

load_data='y';
if exist('m','var')
	load_data=input('Some data is already loaded in the workspace. Replace? (y/n)','s');
end

if strcmp(load_data,'y')

	template_file=[data_dir,non_task_condition,'/',subIDs{1},'_',non_task_condition,'_GSR_matrix.txt'];
	fprintf([template_file,'\n'])
	template=importdata(template_file);
    trimask=logical(triu(ones(size(template))));
    
    n_nodes=size(template,1); % assuming square

	fprintf('Loading %d subjects. Progress:\n',n_subs);

	% load data differently for TPR or FPR
	if do_TPR

		m=zeros(n_nodes,n_nodes,n_subs*2); 
        for i = 1:n_subs
			this_file_task = [data_dir,task_condition,'/',subIDs{i},'_',task_condition,'_GSR_matrix.txt'];
            d=importdata(this_file_task);
    	    d=reorder_matrix_by_atlas(d,mapping_category); % reorder bc proximity matters for most of these
            m(:,i) = d(trimask);
% 			 m(:,:,i) = importdata(this_file_task);
			this_file_non_task = [data_dir,non_task_condition,'/',subIDs{i},'_',non_task_condition,'_GSR_matrix.txt'];
			d=importdata(this_file_non_task);
    	    d=reorder_matrix_by_atlas(d,mapping_category); % reorder bc proximity matters for most of these
            m(:,n_subs+i) = d(trimask);
%             m(:,:,n_subs+i) = importdata(this_file_non_task);
			% print every 50 subs x 2 tasks
			if mod(i,50)==0; printf('%d/%d  (x2 tasks)\n',i,n_subs); end
        end

	else % for FPR

		m=zeros(n_nodes,n_nodes,n_subs);
        for i = 1:n_subs
			this_file_non_task = [data_dir,non_task_condition,'/',subIDs{i},'_',non_task_condition,'_GSR_matrix.txt'];
			d=importdata(this_file_non_task);
    	    d=reorder_matrix_by_atlas(d,mapping_category); % reorder bc proximity matters for most of these
            m(:,i) = d(trimask);
			% print every 100
			if mod(i,100)==0; printf('%d/%d\n',i,n_subs); end
        end   

	end
	
	fprintf('Done.\nReordering matrices.\n');

elseif strcmp(load_data,'n')
	fprintf('Using previously loaded data and assuming already reordered.\n');
else; error('Input must be y or n.');
end


%% Make design matrix and contrast

if do_TPR
	% set up design matrix for one-sample t-test
	% data should be organized: s1_gr1,s2_gr1, ... , sn-1_group2, sn_group2
	dmat=zeros(n_subs_subset*2,n_subs_subset+1);
	dmat(1:(n_subs_subset),1)=1;
	dmat((n_subs_subset+1):end,1)=-1;
	for i=1:n_subs_subset
		dmat(i,i+1)=1;
		dmat(n_subs_subset+i,i+1)=1;
	end

	% set up contrasts - positive and negative
	nbs_contrast=zeros(1,n_subs_subset+1);
	nbs_contrast(1)=1;

	nbs_contrast_neg=nbs_contrast;
	nbs_contrast_neg(1)=-1;

	% set up exchange
	nbs_exchange=[1:n_subs_subset, 1:n_subs_subset];
else
	% set up design matrix for two-sample t-test
	% data should be organized: s1_gr1, ... sn_gr1, sn+1_gr2, ... s2*n_gr2
	dmat=zeros(n_subs_subset,2);
	dmat(1:(n_subs_subset/2),1)=1;
	dmat((n_subs_subset/2+1):end,2)=1;

	% set up contrasts - positive and negative
	nbs_contrast=[1,-1];
	nbs_contrast_neg=[-1,1];

	% set up exchange
	nbs_exchange='';
end

% make edge groupings (for cNBS and SEA)
if strcmp(cluster_stat_type,'cNBS') || strcmp(cluster_stat_type,'SEA')
    edge_groups=load_atlas_edge_groups(n_nodes,mapping_category);
    edge_groups=tril(edge_groups,-1);
    % TODO: in NBS function, should we require zero diag? Automatically clear diag? Something else?
end

%% Assign params to structures

% assign repetition parameters to rep_params
rep_params.data_dir=data_dir;
rep_params.testing=testing;
rep_params.mapping_category=mapping_category;
rep_params.n_repetitions=n_repetitions;
rep_params.n_subs_subset=n_subs_subset;
rep_params.do_TPR=do_TPR;
if do_TPR; rep_params.task_condition=task_condition;
end
rep_params.non_task_condition=non_task_condition;

% assign NBS parameters to UI (see NBS.m)
UI.method.ui=nbs_method; % TODO: revise to include vanilla FDR
UI.design.ui=dmat;
UI.contrast.ui=nbs_contrast;
UI.test.ui=nbs_test_stat; % alternatives are one-sample and F-test
UI.perms.ui=n_perms; % previously: '5000'
UI.thresh.ui=tthresh_first_level; % p=0.01
UI.alpha.ui=pthresh_second_level;
UI.statistic_type.ui=cluster_stat_type; % 'Size' | 'TFCE' | 'Constrained' | 'SEA'
UI.size.ui=cluster_size_type; % 'Intensity' | 'Extent' - only relevant if stat type is 'Size'
if strcmp(cluster_stat_type,'cNBS') || strcmp(cluster_stat_type,'SEA');
    UI.edge_groups.ui=edge_groups; % smn
end
UI.exchange.ui=nbs_exchange;



