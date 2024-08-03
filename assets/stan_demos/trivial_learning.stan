data {
  int<lower=1> N;  // num samples
  array[N] int<lower=0> x; // data
}
parameters {
  real<lower=0> lambda;  // to learn
}
model {
  x ~ poisson(lambda);
}
