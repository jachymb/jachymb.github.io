data {
  vector<lower=0>[5] alpha;
  array[5] int<lower=0> rating;
}
parameters {
  simplex[5] d;
}
model {
  d ~ dirichlet(alpha);
  ratings ~ multinomial(d);
}
generated quantities {
  real average_rating = mean(d);
}
