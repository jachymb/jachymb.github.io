data {
  int<lower=1> N;  // num experiments
  array[N] int<lower=0> successes;
  array[N] int<lower=0> trials;
}
parameters {
  array[N] real<lower=0,upper=1> theta;
  real<lower=0> a, b;
}
model {
  for (i in 1:N) {
    theta ~ beta(a, b);
    successes[i] ~ binomial(trials[i], theta);
    // Assuming trials[i] >= successes[i]
  }
}
