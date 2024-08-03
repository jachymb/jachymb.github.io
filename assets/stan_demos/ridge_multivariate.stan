data {
  int<lower=1> K;    // num features
  int<lower=0> N;    // num samples
  matrix[N, K] x;    // features
  vector[N] y;       // response
  real<lower=0> lambda;
}
parameters {
  vector[K] beta;
  real<lower=0> sigma;
}
model {
  beta ~ normal(0, lambda);
  y ~ normal(x * beta, sigma);
}
