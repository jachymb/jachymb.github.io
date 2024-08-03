data {
  int<lower=1> N;  // num products
  array[N, 5] int<lower=0> ratings;
}
parameters {
  vector<lower=0>[5] alpha;
  array[N] simplex[5] d;
}
model {
  d ~ dirichlet(alpha);  // for all d[i]
  for (i in 1:N) {
    ratings[i] ~ multinomial(d[i]);
  }
}
