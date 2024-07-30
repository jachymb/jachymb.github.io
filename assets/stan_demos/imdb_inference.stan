data {
  vector<lower=0>[5] alpha;
  array[5] int rating;
}
parameters {
  simplex[5] d;
}
model {
  d ~ dirichlet(alpha);
  ratings[i] ~ multinomial(d);
}
