---
title: 'Parametrizing features – how to DIY a prophet'
layout: post
date: 2024-12-08
tags: [machine learning,statistics,case study]
pin: true
math: true
published: false
---

In this article, I will show how we can make a model similar to the one provided by the [Prophet](https://facebook.github.io/prophet/docs/quick_start.html)
library and how we can tweak it to make it even better. 

I have used Prophet in several of my work projects when dealing with time series
and I like its ease of use while being kinda general purpose.
It has decent predictive power, is fast to train and is well interpretable.
But it has its downsides. 
I mentioned in the [article about generalized linear models](/posts/glms)
that a case where least squares methods fail is when the data are positive integers close to zero.
The same is true for Prophet which is actually kinda just least squares on steroids. 
Here, I explain what I consider to be the main "steroids" and how we can DIY code it with [STAN](https://mc-stan.org/),
that Prophet also uses as an engine.

## Feature engineering – a discussion
One way to extend a linear regression (or classification) to cover non-linear cases,
is by adding extra features which are transformed or combined versions of existing features.
For example, when I add the feature $x\cdot y$ for all pairs $x,y$ of existing features (including when $x=y$)
I get a quadratic model. In particular, for univariate linear regression, this fits a parabola instead of a line
and for a linear classifier, the classification boundary may be any one of the conic sections.
We may also include other transformations in the feature engineering phase,
for example some features may be better on log scale, or when modelling a periodicity, a feature $\varphi$ capturing the period phase 
(e.g. number of days since new year for yearly periodicity) may be better expressed as $e^{i\varphi} = (\cos\varphi, \sin\varphi)$
to preserve the model continuity around New Year's Eve.
Furthermore, when working with time series, you may want to use some (autoregressive) window aggregates as features
and there are basically infinite ways how to do that exactly.
All these approaches can be combined to make yet more complex features.



The basic problem with this approach is that this may quickly add a lot of parameters to the model,
increasing the needed amount of data, resp. increases the risk of overfitting.
In some models, this can be resolved using the [kernel trick](https://en.wikipedia.org/wiki/Kernel_method).
Even then, with the feature engineering, there always remains the question:
How do we determine which transformations (or kernel) should we choose?
Ideally, this should be based on some interpretable domain–specific knowledge,
but very often this is unavailable or simply too complicated to reasonably represent.
There are two usual approaches in machine learning:

1. Generate a lot of feature variants from the data you have. 
Then perform some feature selection methods and keep a subset of the features that is measured to work the best.
2. Use deep learning, shove the raw data on the input. 
The front layers of the network learn to do the feature engineering for you. 

The first approach has the advantages of keeping the model better interpretable, requiring a lot less data and less compute resources to achieve comparable accuracy, _when designed to match the problem well_.
Yet, it's often outperformed by deep learning in many cases.
The massive success of deep learning is however due to the "when designed to match the problem well" requirement,
which is actually hard to achieve and requires a lot of expert work in the better case
and in the worse case is simply practically impossible for more complicated problems like advanced image or language processing.

Here, I want to present a third and a bit less common approach, 
which I'd say is conceptually (not necessarily mathematically) somewhere in the middle: 
We have some data transformations, that are based on some domain–specific knowledge 
(e.g. knowing that there are yearly periodicities in the data will make us introduce some periodic transforms)
but we keep their exact form unspecified by defining them as some parametrized functions.
We learn these parameters together with all other parameters, such as [GLM](/posts/glms) coefficients.

## A simple example: Box–Cox transformation
I want to mention this, because parametrized power transforms are a simple tool that I used multiple times during my work, so it's kinda a personal favorite,
and it's also very simple and conceptually goes in the direction I want to explore here,
so consider it a "Hello world!" type of model here.

The Box–Cox transformation is a function $f: \mathbb{R}^+ \to \mathbb{R}$ with a parameter $\lambda \in \mathbb{R}$ given by:

$$f(x\,|\,\lambda) = \begin{cases} 
      \frac{y^{\lambda}-1}{\lambda} & x\ne 0 \\
      \ln y & x=0 
\end{cases}$$

and it is used to find the suitable power $\lambda$ to make some univariate data $y > 0$ "more normal" by estimating 
it by MLE together with $\mu, \sigma$ in the model:

$$f(x\,|\,\lambda) \sim \mathrm{Normal}(\mu, \sigma^2)$$

Surprisingly often, the single parameter is enough to make highly skewed data into a more or less symmetric bump. 
The univariate data here may be any single feature, including the dependent variable (which is the inverse transformed on the prediction output). 
It may be of interest for preprocessing input to normality assuming models like OLS linear regression or PCA. 
In practice, from a pragmatical engineering standpoint, 
it's usually OK to just fit & transform the Box–Cox during the preprocessing step of an ML pipeline.
You can even use it to simply choose another transform: If you fit $\lambda \approx \frac{1}{2}$, it's probably OK to go for square root instead.
But from a statistical estimation perspective, for optimal fit, 
one should learn the parameter $\lambda$ jointly with any other parameters of the model.

This can be seen as somewhat analogous to adding an extra layer to the front of a neural network, that learns what nonlinear transforms to do first,
but it keeps most of the desirable properties of the manual feature engineering approach.

## Modelling periodicity 
One of the main selling points of Prophet is the ability to model seasonality nicely.
We have seen in the previous [GLM](/posts/glms) article simple model which has weekly seasonality
expressed by an indicator feature for weekend, which was one parameter. 
If you have data over many weeks, you can probably expend seven parameters to learn a coefficient
for each one–hot encoded day to make this more precise.
But you probably don't have daily data going for millennia to use the same technique for yearly seasonality.
If we have finer granularity in the time series, such per hour or per minute, we may also want to model daily seasonality.
Or, maybe you believe the Lunar cycle has an effect on the outcome of your measurements.
We need something else to model these, and we take inspiration in Fourier series.
Remember, that a periodic function $f: \mathbb{R}\to\mathbb{R}$ with period $T$ (year, day, ...) can be represented as:

$$f(t\,|\,\alpha,\varphi) = \alpha_0 + \sum_{k=1}^{\infty} \alpha_k \cos\left(\frac{t \cdot 2\pi k}{T} - \varphi_k \right) $$

In classical analysis, $f$ is given, and we want to solve for $\alpha,\varphi$ to obtain the series. 
Here the idea is, that there is an underlying but unknown $f$ which transforms the feature expressing time,
and we take a $K$th partial sum of the series to approximate it 
and learn its parameters  $\alpha,\varphi$ from data ($\alpha_0$ will usually be redundant in practice).
For each periodicity we want to model, we can do this independently with different $T,K$.

We then plug this into whatever GLM together with any other features we have, like follows:
Assume we have the feature matrix in the format $\begin{bmatrix}X' & t\end{bmatrix}$
where $t$ is the column expressing time and $X'$ is a matrix with any number of columns.
We then may instead set $X$ to $\begin{bmatrix}X' & f(t\,|\,\alpha,\varphi)\end{bmatrix}$ if we only want one periodicity without a growth trend,
of perhaps $\begin{bmatrix}X' & t & f(t\,|\,\alpha,\varphi)\end{bmatrix}$ if we want one periodicity plus a linear growth trend
or include multiple transformed columns for more periodicities or other growth functions and so on.

The simplest GLM (normal–identity) is then:

$$ y \sim \mathrm{Normal}\left(X(\alpha,\varphi)\beta, \; \sigma^2\right)$$

As I side note, I used a simpler version of this idea in the [inhomogeneous Poisson process](/posts/inhomogeneous-poisson-process/) article for continuous time.
A bit more complicated variant which can be used, is to replace the harmonic frequencies $2\pi k$ 
by a parameter $\omega_k$ to be estimated. 
Although this introduces new parameters, it allows to set $K$ lower and in some cases then produce better results. 


Doing MLE on such models would be very difficult in practice. 
Here is how STAN and similar probabilistic modelling software frameworks become important.
With its [autodiff](https://en.wikipedia.org/wiki/Automatic_differentiation) implementation,
it makes all the difficult calculations for you and does some gradient descent type of optimization to find MLE (or MAP).
Its sampling algorithm can then be robust against local minima.

## Coding periodicity

```STAN
functions {
  real periodicity(
}
data {
  int<lower=0> N, M, K;  // num samples, num features, Fourier order
  real<lower=0> T;  // period length
  vector[N] t;  // timestamp features
  matrix[N, M] data;  // any other features
}
transformed data {
  vector[K] frequencies = 2 * pi() * linspaced_vector(K, 1, K) / T;
  matrix[N, M+2] X = 
}
parameters {
  real<lower=0> sigma;
  vector[M+2] beta;
  vector<lower=-pi(),upper=pi()>[K] phase_shifts;
  row_vector<lower=0>[K] amplitudes;
}
```
