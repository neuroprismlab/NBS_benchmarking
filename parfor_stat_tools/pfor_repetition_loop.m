function pfor_repetition_loop(i_rep, ids_sampled, RepParams, UI)
    fprintf('* Repetition %d - positive contrast\n',this_repetition)
    
    if use_preaveraged_constrained % not square matrix 
        m_test = zeros(RepParams.n_var, RepParams.n_subs_subset*2);
    else
        m_test = zeros(RepParams.n_nodes*(RepParams.n_nodes - 1)/2, RepParams.n_subs_subset*2);
    end

    rep_sub_ids = ids_sampled(:, i_rep);
     
    if use_both_tasks 
        
        if paired_design
            
            % Comment about m_test
            m_test = pfor_paired_design_extract_subset(rep_sub_ids, ...
                                                       RepParams.brain_data, RepParams.task1, ...
                                                       RepParams.task2, RepParams.mapping_category, ...
                                                       RepParams.do_TPR, RepParams.n_subs_subset, ...
                                                       m_test);    
            
        else
            error('This script hasn''t been fully updated/tested for two-sample yet.');   
            
            util_placeholder_1();
        end
    else

            m_test = pfor_single_task_extract_subset(rep_sub_ids, ...
                                                     RepParams.brain_data, RepParams.task1, ...
                                                     RepParams.mapping_category, m_test);

    end

    UI_new = UI;
    UI_new.matrices.ui = m_test;
    

    nbs = NBSrun_smn(UI_new);
    
    % re-run with negative
    fprintf('* Repetition %d - negative contrast\n',this_repetition)
    UI_new_neg = UI_new;
    % nbs_contrast_neg is not here ....
    UI_new_neg.contrast.ui = UI.nbs_contrast_neg;

    nbs_neg = NBSrun_smn(UI_new_neg);
    

    % check for any positives (if there was no ground truth effect, this goes into the FWER calculation)
    if nbs.NBS.n > 0
        FWER = FWER + 1;
    end

    if nbs_neg.NBS.n > 0
        FWER_neg = FWER_neg + 1;
    end

    % record everything
    if strcmp(cluster_stat_type,'FDR') || contains(cluster_stat_type,'Parametric')

	    % Note: NBS's FDR does not return corrected p-values, only significant edges 
        % (con_mat)--assigning significant edges to a pvalue of "0" and 
        % non-significant to pvalue "1" JUST for summarization purposes
        edge_stats_all(:,this_repetition) = nbs.NBS.test_stat(triumask);
        pvals_all(:,this_repetition) = ~nbs.NBS.con_mat{1}(:); % see above note 
        
        edge_stats_all_neg(:,this_repetition) = nbs_neg.NBS.test_stat(triumask);
        pvals_all_neg(:,this_repetition) = ~nbs_neg.NBS.con_mat{1}(:);  % see above note
        
    else
        
         % TODO: had to vectorize for TFCE... should give all outputs in same format tho
        edge_stats_all(:,this_repetition)=nbs.NBS.edge_stats;
        pvals_all(:,this_repetition)=nbs.NBS.pval(:); 

        edge_stats_all_neg(:,this_repetition)=nbs_neg.NBS.edge_stats;
        pvals_all_neg(:,this_repetition)=nbs_neg.NBS.pval(:); % TODO: same as above
        
        % Todo - add - remove - idk why this is here
        % if strcmp(UI.statistic_type.ui,'Omnibus') % single result for omnibus
        %  cluster_stats_all(this_repetition)=full(nbs.NBS.cluster_stats);
        % cluster_stats_all_neg(this_repetition)=full(nbs_neg.NBS.cluster_stats);
        
        %  else

        cluster_stats_all(:,:,this_repetition)=full(nbs.NBS.cluster_stats);
        cluster_stats_all_neg(:,:,this_repetition)=full(nbs_neg.NBS.cluster_stats);
 
    end
    
end