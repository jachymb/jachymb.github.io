data {
  int<lower=0> N, F; // num samples, fourier order
  row_vector[N] t;          // "timestamps" - single feature
  vector<lower=0>[N] y;     // dependent variable
}
transformed data {
  vector[F] freq = 2 * pi() * linspaced_vector(F, 1, F) / 365;
  matrix[N, 2] x = [t, rep_row_vector(1, N)]'; // add intercept
}
parameters {
  real<lower=0> sigma; // homoscedasticity
  vector[2] beta; // growth and intercept
  vector<lower=-pi(), upper=pi()>[F] phase_shifts;
  row_vector<lower=0>[F] amplitudes;
}
transformed parameters {  // Encoding seasonality to alpha
  vector[N] alpha = (
    amplitudes * cos(freq * t + rep_matrix(phase_shifts, N))
  )';
}
model {
  y ~ normal_id_glm(x, alpha, beta, sigma);
}
