data {
  int<lower=0> N, K;
  array[N] int<lower=0,upper=1> free;
  vector[N] y;
}
transformed data {
  row_vector[N] free_v = to_row_vector(free);
}
parameters {
  real alpha, sigma;
  row_vector[K] beta;
}
model {
  for (n in (K+1):N) {
    row_vector[K] beta_adj = beta .* free_v[n-K:n];
    real total_w = sum(beta_adj);
    if (total_w > 0) {  // Any free within last K
        real mu = alpha + beta_adj * y[n-K:n] / total_w;
        y[n] ~ normal(mu, sigma);
    }
  }
}
