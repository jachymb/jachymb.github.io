data {
  int<lower=1> N;  // num products
  array[N, 5] int<lower=0> ratings;
}
parameters {
  vector<lower=0>[5] alpha;
  array[N] simplex[5] d;
}
model {
  for (i in 1:N) {
    d[i] ~ dirichlet(alpha);                              // can factor out as d ~ dirichlet(alpha);
    ratings[i] ~ multinomial(d[i]);
  }
}
