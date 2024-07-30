data {
  int N;  // num products
  array[N, 5] int ratings;
}
parameters {
  vector<lower=0>[5] alpha;
  array[N] simplex[5] d;
}
model {
  d ~ dirichlet(alpha);
  for (i in 1:N) {
    ratings[i] ~ multinomial(d[i]);
  }
}
