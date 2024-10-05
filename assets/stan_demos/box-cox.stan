functions {
  vector box_cox(vector y, real lambda) {
    if (lambda != 0.0) {
      return (pow(y, lambda) - 1) / lambda;
    } else {
      return log(y);
    }
  }
}
data {
  int<lower=1> N;
  vector<lower=0>[N] y;
}
parameters {
  real lambda;
  real mu;
  real<lower=0> sigma;
}
model {
  box_cox(y, lambda) ~ normal(mu, sigma);
}
