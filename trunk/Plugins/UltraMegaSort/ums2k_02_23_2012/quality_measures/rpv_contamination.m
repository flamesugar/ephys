function [ev,lb,ub] = rpv_contamination(N, T, RP, RPV )
% UltraMegaSort2000 by Hill DN, Mehta SB, & Kleinfeld D  - 07/09/2010
%
% rpv_contamination - get range of contamination
%
% Usage:
%   [ev,lb,ub] = rpv_contamination(N, T, RP, RPV )
%
% Description:
%   Estimates contamination of a cluster based on refractory period
% violations (RPVs).  Estimate of contamination assumes that the 
% contaminating spikes are statistically independent from the other spikes
% in the cluster.  Estimate of the confidence interval assumes Poisson
% statistics.
%
%   Refractory period violations must arise from spikes that were not 
% generated by the neuron that a cluster represents.  We calculate the rate
% of these "rogue" events by dividing the total number of RPV's by the total
% period in which an RPV can occur.  For every true spike in a cluster, if
% a rogue spike occurs immediately before or after, this causes a RPV.
% Therefore, for every true spike in a cluster, there is a period
%
%          tau_rpv = 2*(tau_r - tau_c) 
%
% when refactory period violations can occur if a rogue spike is present, 
% where tau_r is the user-defined refractory period, and tau_c is the 
% user-defined shadow (censored) period. Therefore, the total time in which
% an RPV can occur is 
%
%           T_rpv = N(1-P)tau_rpv 

% where N is the number of spikes in the cluster and P is the probability 
% that a spike is a "rogue" spike.  Finally, we estimate the rate of 
% contamination as
%
%       lambda_rogue = RPV / T_rpv
%
% where RPV is the total number of observed RPV's.  Finally, noting that
%
%       lambda_rogue =  p * N / T
%
% where T is duration of the experiment, we can perform substitution to
% solve for p and plugging in the values for N, T, RPV, tau_r, and tau_c.
%
% Input: 
%   N    - Number of spike events in cluster
%   T    - Duration of recording (s)
%   RP   - Duration of useable refractory period, tau_rp - tau_c (s) (Remember to subtract censor period!)
%   RPV  - Number of observed refractory period violations in cluster
%
% Output:
%   ev   - expected value of % contamination,
%   lb   - lower bound on % contamination, using alpha confidence interval
%   ub   - upper bound on % contamination, using alpha confidence interval
%

   conf_int = 95; % percent confidence interval
   lambda = N/T;  % mean firing rate for cluster 

   % get Poisson confidence interval on number of expected RPVs
   [dummy, interval] = poissfit(RPV, (100-conf_int)/100 ); 
   
   % convert contamination from number of RPVs to a percentage of spikes
   lb = convert_to_percentage( interval(1), RP, N, T, lambda ); 
   ub = convert_to_percentage( interval(2), RP, N, T, lambda ); 
   ev = convert_to_percentage( RPV        , RP, N, T, lambda );
  
end

function p = convert_to_percentage( RPV, RP, N, T, lambda )
    % converts contamination from number of RPVs to a percentage of spikes

    RPVT = 2 * RP * N; % total amount of time in which an RPV could occur
    RPV_lambda = RPV / RPVT; % rate of RPV occurence
    p =  RPV_lambda / lambda; % estimate of % contamination of cluster
    
    % force p to be a real number in [0 1]
    if isnan(p), p = 0; end  
    if p>1, p= 1; end     
        
end
