data {
  int<lower=1> N;
  int<lower=1> K;
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
