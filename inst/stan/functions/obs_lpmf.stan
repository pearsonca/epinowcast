real obs_lpmf(int[] obs, int[,] obs_miss, int dmax, int[] sl, int[] csl, int n_groups,
              vector[] imp_obs, int[] sg, int[] st, int[,] rdlurd,
              vector srdlh, matrix ref_lh, int[] dpmfs, int ref_p, vector[] alpha, real phi) {
  real tar = 0;
  real tar_obs;
  real tar_alpha;
  int n_snaps = num_elements(st);
  int n_obs = num_elements(obs);
  int n_obs_miss = num_elements(obs_miss[1]);
  vector[n_obs] exp_obs_all;
  vector[n_obs] exp_obs;
  vector[n_obs_miss] exp_obs_miss[n_groups] = rep_array(rep_vector(0, n_obs_miss), n_groups);
  
  int g, t, l;
  int ssnap = 1;
  int esnap = 0;

  for (i in 1:n_snaps) {
    g = sg[i];
    t = st[i];
    l = sl[i];
    vector[l] rdlh;
    // Find final observed/imputed expected observation
    tar_obs = imp_obs[g][t];
    // allocate report day effects
    rdlh = srdlh[rdlurd[t:(t + l - 1), g]];
    // allocate share of cases with known reference date
    tar_alpha = alpha[g][t];
    // combine expected final obs and date effects to get expected obs
    esnap += l;
    exp_obs_all[ssnap:esnap] = expected_obs(
      tar_obs, ref_lh[1:l, dpmfs[i]], rdlh, ref_p
    );
    // compute expected final obs with known and missing reference date
    exp_obs[ssnap:esnap] = exp_obs_all * tar_alpha;
    if(t+l>=1+dmax){
      exp_obs_miss[g][max(1 + dmax, t):(t + l)] += exp_obs_all[max(1 + dmax - t, 1):l] * (1 - tar_alpha);
    }
    ssnap += l;
  }
  // observation error model with known reference dates (across all reference times and groups)
  tar = neg_binomial_2_lupmf(obs | exp_obs, phi);
  // observation error model with missing reference dates
  for (k in 1:n_groups) {
    tar += neg_binomial_2_lupmf(obs_miss[k][(1 + dmax):n_obs_miss] | exp_obs_miss[k][(1 + dmax):n_obs_miss], phi);
  }
  return(tar);
}
