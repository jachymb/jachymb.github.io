functions {
    matrix season_log_contribution(vector phase, matrix seasonality_log_amplitudes, matrix seasonality_phases, matrix seasonality_shapes) {
        array[2] int d = dims(seasonality_phases); // can this boilerplate be reduced?
        int order = d[1];
        int n_products = d[2];
        int n_days = size(phase);

        matrix[n_products, n_days] log_contributions = rep_matrix(0, n_products, n_days);
        real tau = 2*pi();

        matrix[n_products, n_days] adjusted_phases, daily_seasonality_log_amplitudes, daily_seasonality_shapes;
        for (i in 1:order) {
            adjusted_phases = tau*(phase * seasonality_phases[i])';
            daily_seasonality_log_amplitudes = rep_matrix(seasonality_log_amplitudes[i]', n_days);
            daily_seasonality_shapes = rep_matrix(seasonality_log_amplitudes[i]', n_days);

            log_contributions += (sin(adjusted_phases)-1) .* daily_seasonality_shapes + daily_seasonality_log_amplitudes;
        }
        //print ("DEBUG season_log_contribution returning"); print(log_contributions);
        return log_contributions;
    }

    matrix compute_rates(real autoregressive_decay, real autoregressive_weight, matrix log_seasonality_contribution, matrix available, matrix sold, matrix unscaled_decays_precomputed, matrix triangle_precomputed) {
        array[2] int d = dims(log_seasonality_contribution); // can this boilerplate be reduced?
        int n_products = d[1];
        int n_days = d[2];

        matrix[n_products, n_days] seasonality_contribution = exp(log_seasonality_contribution);
        //print ("DEBUG compute_rates seasonality_contribution"); print(seasonality_contribution);
        matrix[n_products, n_days] autoregressive_coefficients = (available * pow(unscaled_decays_precomputed, autoregressive_decay)) ./ seasonality_contribution;
        //print ("DEBUG compute_rates autoregressive_coefficients"); print(autoregressive_coefficients);
        matrix[n_products, n_days] autoregressive_coefficient_cumsum = autoregressive_coefficients * triangle_precomputed; //transpose maybe?
        //print ("DEBUG compute_rates autoregressive_coefficient_cumsum"); print(autoregressive_coefficient_cumsum);
        matrix[n_products, n_days] sold_cumsum = sold * triangle_precomputed;
        //print ("DEBUG compute_rates sold_cumsum"); print(sold_cumsum);
        matrix[n_products, n_days] past_rate = autoregressive_coefficients .* sold_cumsum ./ autoregressive_coefficient_cumsum;
        //print ("DEBUG compute_rates past_rate"); print(past_rate);

        return past_rate*autoregressive_weight + (1-autoregressive_weight)*seasonality_contribution;
    }

}

data {
    int<lower=0> year_seasonality_order;
    int<lower=1> n_days;
    int<lower=1> n_products;
    array[n_days] int date_ordinal;
    vector<lower=0,upper=1>[n_days] year_phase; // leap day on Feb 29 has same phase as Feb 28.
    array[n_days] int<lower=1,upper=7> weekday;
    array[n_days] int<lower=0,upper=1> workday;  // currently unused
    array[n_products, n_days] int<lower=0> sold;
    array[n_products, n_days] int<lower=0,upper=1>  available;
}

transformed data {
    matrix[n_products, n_days] available_m = to_matrix(available);
    matrix[n_products, n_days] sold_m = to_matrix(sold);

    matrix[n_days, n_days] unscaled_decays_precomputed, triangle_precomputed;

    for (day1 in 1:n_days) {
        for (day2 in 1:n_days) {
            unscaled_decays_precomputed[day2, day1] = day1 <= day2? exp(day1-day2) : 0;
            triangle_precomputed[day2, day1] = day1 <= day2;
        }
    }
    //print("DEBUG transformed data unscaled_decays_precomputed"); print(unscaled_decays_precomputed);
    //print("DEBUG transformed data triangle_precomputed"); print(triangle_precomputed);

}

parameters {

    real<lower=0> autoregressive_decay;
    real<lower=0,upper=1> autoregressive_weight;

    real global_log_base_rate_mean;
    real<lower=0> global_log_base_rate_std;

    vector[n_products] log_base_rate;

    matrix[n_products, 7] weekday_log_coefficients;
    matrix<lower=0,upper=1>[year_seasonality_order, n_products] year_seasonality_phases; // needs to be rescaled to 2pi
    matrix[year_seasonality_order, n_products] year_seasonality_log_amplitudes;
    matrix<lower=0>[year_seasonality_order, n_products] year_seasonality_shapes;

    vector[7] global_log_weekday_mean;
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

    matrix[n_products, n_days] log_seasonality_contribution = rep_matrix(log_base_rate, n_days);

    log_seasonality_contribution += season_log_contribution(year_phase, year_seasonality_log_amplitudes, year_seasonality_phases, year_seasonality_shapes);
    log_seasonality_contribution += weekday_log_coefficients[, weekday];
    //print("DEBUG transformed parameters log_seasonality_contribution");print(log_seasonality_contribution);

    matrix[n_products, n_days] rates = compute_rates(autoregressive_decay, autoregressive_weight, log_seasonality_contribution, available_m, sold_m, unscaled_decays_precomputed, triangle_precomputed);
    //print("DEBUG transformed parameters rates");print(rates);

    // DEBUG SECTION - internals of compute_rates
        matrix[n_products, n_days] seasonality_contribution = exp(log_seasonality_contribution);
        matrix[n_products, n_days] autoregressive_coefficients = (available_m * pow(unscaled_decays_precomputed, autoregressive_decay)) ./ seasonality_contribution;
        matrix[n_products, n_days] autoregressive_coefficient_cumsum = autoregressive_coefficients * triangle_precomputed; //transpose maybe?
        matrix[n_products, n_days] sold_cumsum = sold_m * triangle_precomputed;
        matrix[n_products, n_days] past_rate = autoregressive_coefficients .* sold_cumsum ./ autoregressive_coefficient_cumsum;


}

model {
    //print("DEBUG target A ", target());
    autoregressive_decay ~ lognormal(0, 0.01);
    autoregressive_weight ~ uniform(0, 1);
    //print("DEBUG target B ", target());

    // Top-level priors
    global_log_base_rate_mean ~ normal(0, 1); // Choice of parameters up to debate, but normal should be ok
    global_log_base_rate_std ~ scaled_inv_chi_square(1, 1); // Very much debatable choice
    global_log_weekday_mean ~ normal(0, 1);
    global_log_weekday_std ~ scaled_inv_chi_square(1, 1); // Very much debatable choice
    global_year_seasonality_shapes_nu  ~ gamma(2, 2);  // idk, need a positive number
    global_year_seasonality_shapes_sigma ~ gamma(2,2);  // idk, need a positive number
    global_year_seasonality_log_amplitudes_mean ~ normal(0, 1);
    global_year_seasonality_log_amplitudes_std ~ scaled_inv_chi_square(1, 1);
    //print("DEBUG target C ", target());

    // Middle level priors

    log_base_rate ~ normal(global_log_base_rate_mean, global_log_base_rate_std);  // same for all products
    //print("DEBUG target D ", target());


    for (w in 1:7) {
        weekday_log_coefficients[, w] ~ normal(global_log_weekday_mean[w], global_log_weekday_std);
    }

    //print("DEBUG target E ", target());

    for (i in 1:year_seasonality_order) {
        year_seasonality_phases[i] ~ beta(global_year_seasonality_phases_alpha, global_year_seasonality_phases_beta);
        year_seasonality_log_amplitudes[i] ~ normal(global_year_seasonality_log_amplitudes_mean, global_year_seasonality_log_amplitudes_std);
        year_seasonality_shapes[i] ~ scaled_inv_chi_square(global_year_seasonality_shapes_nu, global_year_seasonality_shapes_sigma);
    }
    //print("DEBUG target F ", target());



    // Bottom-level model
    for (product in 1:n_products) {
        for (day in 2:n_days) {
            real rate = rates[product, day];
            if (! is_nan(rate)) {
                sold[product, day] ~ poisson(rate);
            }
        }
    }
    //print("DEBUG target G ", target());

}
generated quantities {
    // for debug, eventually should be deleted when I', sure everything works ok
    matrix[n_days, n_days] unscaled_decays_precomputed_copy, triangle_precomputed_copy;
    unscaled_decays_precomputed_copy = unscaled_decays_precomputed;
    triangle_precomputed_copy = triangle_precomputed;
    //print("DEBUG generated quantities unscaled_decays_precomputed_copy"); print(unscaled_decays_precomputed_copy);
    //print("DEBUG generated quantities unscaled_decays_precomputed_copy"); print(unscaled_decays_precomputed_copy);

}
