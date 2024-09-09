data {
  int<lower=1> N;  // num experiments
  array[N] int<lower=0> successes;
  array[N] int<lower=0> failures;
}
parameters {
  vector<lower=0,upper=1>[N] theta;
  real<lower=0> a, b;
}
model {
  for (i in 1:N) {
    int n = successes[i] + failures[i];
    theta ~ beta(a, b);
    successes[i] ~ binomial(n, theta);
  }
}
