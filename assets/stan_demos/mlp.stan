data {
    int<lower=1> M, N, K;
    matrix[M, N] x;
    array[M] int<lower=0,upper=1> y;
}
parameters {
    matrix[N, K] input_layer_w;
    matrix[K, N] hidden_layer_w;
    vector[N] output_layer_w;
}
transformed parameters {
    vector[M] mlp_output = atan(
        atan(x * input_layer_w) * hidden_layer_w
    ) * output_layer_w;
}
model {
  y ~ bernoulli_logit(mlp_output);
}
