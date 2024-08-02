data {
  int<lower=0> N, F;
  row_vector[N] t;          // "timestamps" - single feature
  vector<lower=0>[N] y;
}
transformed data {
  vector[F] freq = 2 * pi() * linspaced_vector(F, 1, F) / 365;
  matrix[2, N] x = [t, rep_row_vector(1, N)];  // add intercept
}
parameters {
  real<lower=0> sigma;
  vector[2] beta;
  vector<lower=-pi(),upper=pi()>[F] phase_shifts;
  row_vector<lower=0>[F] amplitudes;
}
transformed parameters {
  row_vector[N] alpha;         // seasonality
  {
	matrix[F, N] phases = ;
    alpha = amplitudes * cos(freq * t + rep_matrix(phase_shifts, N));
  }
}
model {
  y ~ normal_id_glm(x', alpha', beta, sigma);
}
