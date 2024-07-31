functions {
  real my_poisson_lpmf(array[] int x, real lambda) {
    return (
      - size(x)*lambda
      - sum(lgamma(to_vector(x)+1))
      + log(lambda)*sum(x)
    );
  }
}
data {
  int N;
  array[N] int<lower=0> x;
}
parameters {
  real<lower=0> lambda;
}
model {
  target += my_poisson_lpmf(x | lambda);
}
