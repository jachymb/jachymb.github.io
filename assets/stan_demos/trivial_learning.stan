data {
  int N;
  array[N] int<lower=0> x;
}
parameters {
  real<lower=0> lambda;
}
model {
  x ~ poisson(lambda);
}
