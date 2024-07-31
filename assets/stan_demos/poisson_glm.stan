data {
  int<lower=0> N;
  int<lower=0> K;
  array[N] int<lower=0> y;
  matrix[N, K] x;  // features
}
parameters {
  real alpha;
  vector[K] beta;
}
model {
  y ~ poisson_log_glm(x, alpha, beta);
}
