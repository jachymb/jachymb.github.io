data {
  int<lower=0> N, F;
  array[N] int x;          // "timestamps"
  vector<lower=0>[N] y;
}
transformed data {
  row_vector[N] t = to_row_vector(x);
  vector[F] freq = 2 * pi() * linspaced_vector(F, 1, F) / 365;
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
  y ~ normal_id_glm(t, alpha, [beta]', sigma);
}
