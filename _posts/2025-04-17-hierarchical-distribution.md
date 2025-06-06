---
title: 'A hierarchical model for product allocation'
layout: post
date: 2025-04-17
tags: [bayesian statistics,statistics,probabilistic modelling]
pin: true
math: true
published: true
lang: en
---
<script>
window.MathJax = {
  loader: {load: ['[tex]/boldsymbol']},
  tex: {packages: {'[+]': ['boldsymbol']}}
};
</script>

In this article, I present a hierarchical (Bayesian) model for the problem
of allocating product stocks to stores.
This is an approach to the logistical business problem:
Given some amount of a product from a supplier, how much should be logistics allocate to each of their stores?
We have historical records of per-store product sales, that we can use as statistical data.
This article may also serve as a motivating introduction to hierarchical modelling.
It's similar in nature to textbook problems, but focused on a particular business problem.

In practice, this problem is more complicated, but let's start with a simplification to illustrate the main ideas.
We can formalize the problem mathematically as follows: We have $n$ products and $k$ stores.
The historical data we have available are counts of SKUs sold per-store, a
table of integers $n_{ij}$ with products as rows and stores as columns.
We want to identify the probability distribution over the set of stores,
which says that a customer who is buying a given product will do so in a place where the store needs to serve it.
Since the set of stores is finite, this probability distribution is obviously categorical, but how do we estimate its parameters from the data?

It is a reasonable assumption, that the purchases are independent:
One customer doesn't affect the store location where the next customer will buy the same thing.
Therefore, for a given product, the probability distribution of the counts of purchases is [multinomial](https://en.wikipedia.org/wiki/Multinomial_distribution). 
(The multinomial probability distribution is by-definition the counts of independent categorical trials. The number of trials parameter is given implicitly in the data.)

Furthermore, the true probability distributions for the products are known to be somewhat similar:
If a store serves a large region, it will have high probability of being selected by the next customer regardless of which product they are buying.
However, they aren't always exactly the same, there may be reasons why some product behave differently than others:
For example in poorer regions, the customers will be more price-sensitive and rather choose a cheaper alternative.
In a warm region, products for air conditioning will be more in demand. Etc.

# Naïve Approach 1 – No pooling
A simple idea that may immediately come to mind is this: 
For each product simply calculate the per-store proportions by dividing the per-store counts by the total count.
$$\begin{equation}\hat{p}_{ij} = \frac{n_{ij}}{\sum_k n_{ik}}\label{nopooling}\end{equation}$$
After all, this is the MLE for the categorical/multinomial distribution. 
So are we done?

Well, not so fast. The problem is that we don't have enough data for each product.
An important case is a new product for which the counts in our dataset are exactly 0 for each store.
Then the proportion is even mathematically undefined. 
A similar issue is for a product that was initially only supplied in a low quantity and is being resupplied:
we would be doing statistics on too small amount of data and this will lead to some wild inaccuracies in some cases.
For example, for a low amount of data, it may easily happen that there are zero records of a customer buying the product in a certain store,
but the product is still offered there and a future customer may buy it, so even if the historical proportion is 0,
the logistics still need to send at least something to the store. 
It can be stated as an additional constraint that $\hat{p}_{ij} > 0$.

# Naïve Approach 2 – Full pooling
Since we don't have enough data for some products, 
how about we sum all the per-store values together and calculate just one vector of proportions $\hat{p}_{.j}$ and use that for all products $i$?
After all, we are assuming they behave similarly.

$$ \begin{equation}\hat{p}_{.j} = \frac{\sum_k n_{kj}}{\sum_{kl} n_{kl}}\label{fullpooling}\end{equation}$$


In practice, this would lead to a much better result than the no pooling approach, 
but it disrespects the fact that the products do actually behave differently. We can do better!
 
# Regularization – a dirty trick or a viable fix to no pooling?
A trick one may come up with to solve the requirement $$\hat{p}_{ij} > 0$$
with no pooling approach is to add some quantity
to all the historical records. This is a type of regularization. Let's say we add +1 to all $n_{ij}$. 
This guarantees no zeros in the numerator $\eqref{nopooling}$ and the constraint is met. Cool, but why +1? Why not +100? Why not +0.5?
It is arbitrary and would need a some justification that we don't have at this point.

But this idea isn't without a merit.
We could refine it by saying that this quantity denoted $\alpha_j$ is different per store $j$,
and it somehow captures how big the store is apriori.
Can perhaps the vector $\alpha$ be the proportion vector from full pooling $\eqref{fullpooling}$?
Well, almost, but no.
The proportion is $0 < p_{.j} < 1$, but for the regularization constants we can only say: $0 < \alpha_j$.
However, $\boldsymbol\alpha$ would be reasonably set to a scalar multiple of $\mathbf{p}$, i.e. $\boldsymbol\alpha = \lambda \cdot \mathbf{p}$.
The $\lambda \in \mathbb{R}, 0 < \lambda$ would still be left arbitrary, although we reduced the problem to just one degree of freedom.

This it thus still an incomplete solution,
but it suggests that exploiting the similarity assumption, we may extract more information from the data than what no pooling approach is doing, without completely disrespecting the requirement for the per-product probability distributions to be different. 

# Compromise – a hierarchical model
The above regularization can in fact be derived from the following bayesian model:

$$\begin{align*}
\mathbf{n}_{i} \sim& \mathrm{Multinomial}(\mathbf{p}_i) \\
\mathbf{p}_i \sim& \mathrm{Dirichled}(\boldsymbol\alpha)\end{align*}$$

Then, assuming $\boldsymbol\alpha$ is known, the following estimate is MAP (maximum aposteriori):

$$ \hat{p}_{ij} = \frac{n_{ij}+\alpha_j}{\sum_k (n_{ik} + \alpha_k)}$$

which is just a formalization of the regularization above.

Now a hierarchical model isn't truly bayesian: 
We aren't studying the posterior distribution, and we can't because $\boldsymbol\alpha$ is not actually known.
We still just want a point estimate.
But the idea is, we aren't just taking a point estimate of $\mathbf{p}$, 
but rather a MLE of the joint model with parameters $\mathbf{p}, \boldsymbol\alpha$.
To rephrase: $\boldsymbol\alpha$ isn't some sort of hyperparameter, it's an ordinary parameter to be learned from data.
However, in the joint model, it interacts with the parameters $\mathbf{p}$, essentially regularizing them in the way described above.

This is a middle ground between the above two approaches: 
For products with lots of data, the effect of the regularization will be weak, and they may show their individual specifics if there is data to back it, similar to no pooling.
For products with not enough data, the model will regularize them to be estimated somewhere around the global average, similar to full pooling.
We can quantify this by identifying $\hat{\lambda} = \sum_j \hat{\alpha}_j$ and interpret this value as a measure of overall product similarity:
higher $\hat{\lambda}$ means higher overall similarity and thus stronger overall regularization.

Standard numerical algorithms can be used to find the MLE. It is straightforward to code in Stan (see appendix), which does all the heavy lifting with the optimize method.

In practice, this leads to up to 5% improvement over the full pooling approach in Alza, measured in terms of either [KL divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence) or [total variational distance](https://en.wikipedia.org/wiki/Total_variation_distance_of_probability_measures), when comparing
the fitted model to the proportions on test data.

# Complication in real life business – forbidden product store combinations
As I said the above is just a simplification:
One of the obstacles in real life is that certain products should never be allocated to some stores.
Perhaps it requires a specialized type of storage (e.g. food has different requirements than electronics) 
the store is not equipped with,
or perhaps it's a localization issue (e.g. when a product is localized to Czech only, it mustn't be sent to a Hungarian store.)
We could represent this constraint with a boolean matrix $b_{ij}$ which says whether the combination of product $i$ and store $j$ is allowed.

In the model, the constraint is mathematically expressed as:

$p_{ij} = 0 \iff b_{ij} = 0$ 

This equivalence tells us that we should not fit the values $p_{ij}$ where $b_{ij}=0$ from
data, as these are already known.
If for a vector $a$ we denote by $a[\mathbf{b}_i]$ the subvector of $a$ masked by a boolean vector $\mathbf{b}_i$, we can simply refine the earlier model as:

$$\begin{align*}
\mathbf{n}_{i}[\mathbf{b}_i] \sim& \mathrm{Multinomial}(\mathbf{p}_i[\mathbf{b}_i]) \\
\mathbf{p}_i[\mathbf{b}_i] \sim& \mathrm{Dirichled}(\boldsymbol\alpha[\mathbf{b}_i])\end{align*}$$

for each product $i$. The parameters we are then fitting are entries of the (row stochastic) matrix $\mathbf{p}$ wherever $b_{ij}=1$ and also the entire vector $\boldsymbol\alpha$.
This is a bit tricky to actually code efficiently, especially with regard to the simplex constraint over $\mathbf{p}_i[\mathbf{b}_i]$, but it can be done.
If you're interested, write me. 

# Complication in real life business – outlier purchases
Another complication are purchses of large amounts of SKUs by the same customer at one time.
Imagine a new product of which we order 1000 SKUs. Usually, customers buy 1 or sometimes 2 pcs. Then someone buys 500 and we soon need to resupply.
If we compute the proportions from this data, the store where the outlier customer bought it will falsely seem more popular.
Technically speaking, this is a violation of the independence assumption.

A solution here is to construct $n_{ij}$ as the counts of purchases, not totals of SKUs sold.
If we suspect large purchases may be more common for some stores, we should model the totals separately, 
using a discrete heavy-tailed distribution, perhaps something like [Beta negative binomial](https://en.wikipedia.org/wiki/Beta_negative_binomial_distribution).
We can do this per-store and then weight $\hat{p}_{ij}$ by the totals sold expectation value of that distribution.

# References

1.  [Bayesian Data Analysis, Third Edition](https://sites.stat.columbia.edu/gelman/book/), by Andrew Gelman, John Carlin, Hal Stern, David Dunson, Aki Vehtari, and Donald Rubin

# Appendix: Stan code for the simple hierarchical model

```stan
data {
    int<lower=0> num_stores;
    int<lower=0> num_products;
    array[num_products, num_stores] int<lower=0> n;
}
parameters {
    vector<lower=0>[num_stores] alpha;
    array[num_products] simplex[num_stores] p;
}
model {
    p ~ dirichlet(alpha);
    for (i in 1:num_products) {  // multinomial_lpmf not vectorized yet
        n[i] ~ multinomial(p[i]);
    }
}
```
