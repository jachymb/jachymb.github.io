data {
  int<lower=0> N, K, F;
  matrix[N, K] x;          // features
  vector[N] days;          // "timestamps"
  vector<lower=0>[N] y;
}
parameters {
  real<lower=0> sigma;
  vector[K] beta;
  vector<lower=-pi(),upper=pi()>[F] phase_shifts;
  vector<lower=0>[F] amplitudes;
}
transformed parameters {
  vector[N] alpha;         // seasonality
  {
    row_vector[F] freq = 365/linspaced_row_vector(F, 1, F);
  	matrix[N, F] periods = days * freq;
	  matrix[N, F] phases = rep_matrix(phase_shifts', N);
    alpha = cos(periods + phases) * amplitudes;
  }
}
model {
  y ~ normal_id_glm(x, alpha, beta, sigma);
}
