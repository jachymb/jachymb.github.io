data {
  int<lower=1> K;
  int<lower=K+1> N;
  matrix[N, K] x;
  vector[N] y;
}
parameters {
  vector[K] beta;
  real<lower=0> sigma;
}
model {
  y ~ normal(x * beta, sigma);
}
