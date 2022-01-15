%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% User-defined parameters for running NBS benchmarking
%
% Can define all numerical arguments as numeric or string types
% (Original NBS designed to parse string data)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Paths %%%
% if true, will update paths using system and paths in setpaths.m
% if false, will use the paths defined below
system_dependent_paths=1;

%%% Scripts %%%
% NBS toolbox, summary/vis scripts (structure_data, draw_atlas_boundaries, summarize_matrix_by_atla)
nbs_dir='/Volumes/GoogleDrive/My Drive/Lab/Misc/Software/scripts/Matlab/fmri/NBS1.2';
other_scripts_dir='/Volumes/GoogleDrive/My Drive/Steph-Lab/Misc/Software/scripts/Matlab/myscripts/NBS_benchmarking/support_scripts/'; 

%%% Data Parameters %%%
% Data dir contains the pre-created input files (parsed in setup_benchmarking.m):
%   - input data files: each n_nodes x n_nodes x n_subjects
%     naming convention: [data_dir, task1, '/', <ID>, '_', task1, data_type_suffix[;
%   - subject IDs file: list of n_subjects by ID
%     naming convention: [data_dir, task1, subIDs_suffix]; 
data_dir='/Users/steph/Documents/data/mnt/hcp_1200/matrices/';
output_dir='/Users/steph/Documents/data/mnt/NBS_benchmarking_results/';
task1='WM';         % for TPR: 'EMOTION' | 'GAMBLING' | 'LANGUAGE' | 'MOTOR' | 'RELATIONAL' | 'SOCIAL' | 'WM'
task_gt='GAMBLING'; % for ground truth (can use truncated, e.g., 'REST_176frames')
task2='REST';       % for FPR or TPR contrast ('REST2' for FPR)
subIDs_suffix='_subIDs.txt';        % see naming convention
data_type_suffix='_GSR_matrix.txt'; % see naming convention 

%%% Model %%%
do_TPR=1;
use_both_tasks=1; % for a paired-sample test
paired_design=1; % currently required if using a paired design

%%% Trimmed Scans %%%
% FOR GROUND TRUTH CALCULATION ONLY
% Specify whether to use resting runs which have been trimmed to match each task's scan duration (in no. frames for single encoding direction; cf. https://protocols.humanconnectome.org/HCP/3T/imaging-protocols.html)
% Note: all scans were acquired with the same TR
use_trimmed_rest=0; % default = 0
n_frames.EMOTION=176;
n_frames.GAMBLING=253;
n_frames.LANGUAGE=316;
n_frames.MOTOR=284;
n_frames.RELATIONAL=232;
n_frames.SOCIAL=274;
n_frames.WM=405;
n_frames.REST=1200;
n_frames.REST2=1200;

%%% Resampling parameters %%%
n_workers=15; % num parallel workers for parfor, best if # workers = # cores
mapping_category='subnetwork'; % for cNBS
n_repetitions=500;  % 500 recommended
n_subs_subset=40;   % 40 | 80 | 120
                    % size of subset is full group size (N=n*2 for two sample t-test or N=n for one-sample)

%%% NBS parameters %%%
nbs_method='Run NBS'; 
nbs_test_stat='t-test';     % 't-test' | 'one-sample' | 'F-test' 
                            % Current model (see design matrix in setup_benchmarking.m) only designed for t-test
n_perms='1000';             % default = 1000, more conservative = 5000
tthresh_first_level=3.1;    % t=3.1 corresponds with p=0.005-0.001 (DOF=10-1000)
                            % Only used if cluster_stat_type='Size'
pthresh_second_level=0.05;  % FWER or FDR rate
all_cluster_stat_types={'Size'}; % 'Parametric_Bonferroni' | 'Parametric_FDR' | 'Size' | 'TFCE' | 'Constrained' | 'Constrained_FDR' | 'Omnibus' | 'SEA' (under construction)
                            % misnomer - "cluster_stat_types" -> "stat_types"
                            % edge: 'Parametric_Bonferroni', 'Parametric_FDR', 'FDR' (nonparametric)
                            % can specify multiple, e.g.,: {'Size', 'TFCE'}
                            % Constrained uses Shen atlas imported in setup_benchmarking.m
cluster_size_type='Extent'; % 'Intensity' | 'Extent'
                            % Only used if cluster_stat_type='Size'
omnibus_type='Multidimensional_cNBS';  % 'Threshold_Positive' | 'Threshold_Both_Dir' | 'Average_Positive' | 'Average_Both_Dir' | 'Multidimensional_cNBS' | 'Multidimensional_all_edges' 
                                    % Only used if cluster_stat_type='Omnibus'
omnibus_type_gt='Multidimensional_all_edges';


%%%%% DEVELOPERS ONLY %%%%%
% Use a small subset of permutations for faster development -- inappropriate for inference

testing=0;
test_n_perms=100;
test_n_repetitions=100;
test_n_workers=4;

