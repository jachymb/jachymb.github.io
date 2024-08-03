data {
  int<lower=1> K;
  int<lower=0> N;
  matrix[N, K] x;
  vector[N] y;
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
