data {
    int<lower=0> year_seasonality_order;
    int<lower=1> n_days;
    int<lower=1> n_products;
    array[n_days] int date_ordinal;
    array[n_days] real<lower=0,upper=1> year_phase; // leap day on Feb 29 has same phase as Feb 28.
    array[n_days] int<lower=1,upper=7> weekday;
    array[n_days] int<lower=0,upper=1> workday;  // currently unused
    array[n_products, n_days] int<lower=0> sold;
    array[n_products, n_days] int<lower=0,upper=1>  available;
}
transformed data {
    matrix[n_products, n_days] sold_m = to_matrix(sold);
    matrix[n_products, n_days] available_m = to_matrix(available);
    real tau=2*pi();
}
parameters {

    real<lower=0> autoregressive_decay;
    real<lower=0,upper=1> autoregressive_weight;

    real global_log_base_rate_mean;
    real<lower=0> global_log_base_rate_std;

    array[n_products] real log_base_rate;

    array[n_products, 7] real weekday_log_coefficients;
    matrix<lower=0,upper=1>[n_products, year_seasonality_order] year_seasonality_phases; // needs to be rescaled to 2pi
    matrix[n_products, year_seasonality_order] year_seasonality_log_amplitudes;
    matrix<lower=0>[n_products, year_seasonality_order] year_seasonality_shapes;

    ordered[7] global_log_weekday_mean;
    // Assuming the std is same for every weekday. This is by Occam's razor, but this assumption is open to refutation attempts
    real<lower=0> global_log_weekday_std;
    real<lower=0> global_year_seasonality_shapes_nu;
    real<lower=0> global_year_seasonality_shapes_sigma;

    real<lower=0> global_year_seasonality_phases_alpha;
    real<lower=0> global_year_seasonality_phases_beta;

    real global_year_seasonality_log_amplitudes_mean;
    real<lower=0> global_year_seasonality_log_amplitudes_std;
}
transformed parameters {

    matrix[n_products, n_days] log_seasonality_contribution;

    for (product in 1:n_products) {
        for (day in 1:n_days) {

            log_seasonality_contribution[product, day] = log_base_rate[product];

            log_seasonality_contribution[product, day] += sum(year_seasonality_log_amplitudes[product] + (sin(tau*(year_phase[day] + year_seasonality_phases[product]))-1) .* year_seasonality_shapes[product]);
            // the sum() is over year_seasonality_order indices
            log_seasonality_contribution[product, day] += weekday_log_coefficients[product, weekday[day]];

        }
    }

    row_vector[n_days] decays_precomputed = exp(-reverse(linspaced_row_vector(n_days, 0, n_days-1) * autoregressive_decay));
    matrix[n_products, n_days] seasonality_contribution = exp(log_seasonality_contribution);

    array[n_products, n_days] real<lower=0> rates = rep_array(0, n_products, n_days);

    {
        row_vector[n_days-1] autoregressive_coefficients;
        int prev;
        real past_rate_weight;
        real past_rate;

        for (product in 1:n_products) {
            for (day in 2:n_days) {
                if (available[product, day]) {
                    prev = day - 1;
                    autoregressive_coefficients[1:prev] = available_m[product, 1:prev] .* decays_precomputed[n_days-prev+1:n_days] ./ seasonality_contribution[product, 1:prev];
                    past_rate_weight = sum(autoregressive_coefficients[1:prev]);
                    if (past_rate_weight > 0) {
                        past_rate = sum(sold_m[product, 1:prev] .* autoregressive_coefficients[1:prev]) / past_rate_weight; // weighted sum of previous sold

                        rates[product, day] = past_rate*autoregressive_weight + (1-autoregressive_weight)*seasonality_contribution[product, day];
                    }
                }
            }
        }
    }
}

model {
    autoregressive_decay ~ lognormal(0, 0.01);
    autoregressive_weight ~ uniform(0, 1);

    // Top-level priors
    global_log_base_rate_mean ~ normal(0, 1); // Choice of parameters up to debate, but normal should be ok
    global_log_base_rate_std ~ scaled_inv_chi_square(1, 1); // Very much debatable choice
    global_log_weekday_mean ~ normal(0, 1);
    global_log_weekday_std ~ scaled_inv_chi_square(1, 1); // Very much debatable choice
    global_year_seasonality_shapes_nu  ~ gamma(2, 2);  // idk, need a positive number
    global_year_seasonality_shapes_sigma ~ gamma(2,2);  // idk, need a positive number
    global_year_seasonality_log_amplitudes_mean ~ normal(0, 1);
    global_year_seasonality_log_amplitudes_std ~ scaled_inv_chi_square(1, 1);

    // Middle level priors

    for (product in 1:n_products) {
        log_base_rate[product] ~ normal(global_log_base_rate_mean, global_log_base_rate_std);  // same for all products


        for (w in 1:7) {
            weekday_log_coefficients[product, w] ~ normal(global_log_weekday_mean[w], global_log_weekday_std);
        }

        for (i in 1:year_seasonality_order) {
            year_seasonality_phases[product, i] ~ beta(global_year_seasonality_phases_alpha, global_year_seasonality_phases_beta);
            year_seasonality_log_amplitudes[product, i] ~ normal(global_year_seasonality_log_amplitudes_mean, global_year_seasonality_log_amplitudes_std);
            year_seasonality_shapes[product, i] ~ scaled_inv_chi_square(global_year_seasonality_shapes_nu, global_year_seasonality_shapes_sigma);
        }
    }



    // Bottom-level model
    for (product in 1:n_products) {
        for (day in 2:n_days) {
            if (rates[product, day] > 0) {
                sold[product, day] ~ poisson(rates[product, day]);
            }
        }
    }
}
