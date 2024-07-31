data {
  int<lower=0> N; // Number of observed events
  real<lower=0> T; // End of observation interval
  vector<lower=0, upper=T>[N] t; // Times of events
}
parameters {
  real alpha, beta; // Assuming rate growth is linear
}
model {
  // Log-likelihood contribution from observed events
  target += alpha + beta * t;
  // For "unobserved" events it is ∫₀ᵀ e^(α + β*t) dt
  target += -exp(alpha)*(exp(beta * T) - 1)/beta;
}
