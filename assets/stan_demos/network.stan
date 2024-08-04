data {
  int<lower=1> N;
  array[N] int<lower=0,upper=1> r, s, w;
}
parameters {
  real<lower=0,upper=1> pr;
  array[2] real<lower=0,upper=1> ps;
  array[2, 2] real<lower=0,upper=1> pw;
}
model {
  for (i in 1:N) {
    r[i] ~ bernoulli(pr);  // can factor out
    s[i] ~ bernoulli(ps[r[i]]);
    w[i] ~ bernoulli(pw[r[i], s[i]]);
  }
}
