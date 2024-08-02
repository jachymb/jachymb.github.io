data {
  int<lower=0> N, K;
  array[N] int<lower=0,upper=1> free;
  vector[N] y;
}
transformed data {
  vector[N] free_v = to_vector(free);
}
parameters {
  real alpha, sigma;
  row_vector[K] beta;
}
model {  // code not efficient, should be vectorized
  for (n in (K+1):N) {
    vector beta_adj = beta .* free_v[n-K:n];
    real total_w = sum(beta_adj);
    if (total_w > 0) {  // Any free within last K
        real mu = alpha + beta_adj * y[n-K:n] / total_w;
        y[n] ~ normal(mu, sigma);
    }
  }
}
