data {
  int<lower=1> K;    // num features
  int<lower=K+1> N;  // num samples
  array[N] int<lower=0> y;  // response
  matrix[N, K] x;    // features
}
parameters {
  real alpha;
  vector[K] beta;
}
model {
  y ~ poisson_log_glm(x, alpha, beta);
}
