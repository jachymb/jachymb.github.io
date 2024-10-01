data {
  int<lower=1> K; // num experiments
  array[K] int<lower=0> x; // successes
  array[K] int<lower=0> n; // trials
  // Assuming n[i] >= x[i]
}
parameters {
  array[K] real<lower=0,upper=1> theta;
  real<lower=0> a, b;
}
model {
  for (i in 1:K) {
    theta ~ beta(a, b);
    x[i] ~ binomial(n[i], theta);

  }
}
