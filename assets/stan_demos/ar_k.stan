data {
  int<lower=1> K;    // model order
  int<lower=K+1> N;  // dataset size
  vector[N] y;
}
parameters {
  real alpha;
  row_vector[K] beta;
  real<lower=0> sigma;
}
model {
  for (n in (K+1):N) {
    real mu = alpha + (beta * y[n-K:n]);
    y[n] ~ normal(mu, sigma);
  }
}
