data {
  int<lower=0> N, K, F;
  row_vector[N] x;          // "timestamps"
  vector<lower=0>[N] y;
}
transformed data {
  vector[F] freq = 365 / linspaced_vector(F, 1, F);
}
parameters {
  real<lower=0> sigma;
  real beta;
  vector<lower=-pi(),upper=pi()>[F] phase_shifts;
  vector<lower=0>[F] amplitudes;
}
transformed parameters {
  vector[N] alpha;         // seasonality
  {  matrix[N, F] phases = rep_matrix(phase_shifts', N);
     alpha = cos(freq * x + phases) * amplitudes;
}}
model {
  y ~ normal_id_glm(x, alpha, [beta]', sigma);
}
