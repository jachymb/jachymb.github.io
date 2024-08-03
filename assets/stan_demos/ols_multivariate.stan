data {
  int<lower=1> K;    // num features
  int<lower=K> N;  // num samples
  matrix[N, K] x;    // features
  vector[N] y;       // response
}
parameters {
  vector[K] beta;
  real<lower=0> sigma;
}
model {
  y ~ normal(x * beta, sigma);
}
