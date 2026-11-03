---
title: 'Modelling periodicity with GLMs – how to DIY a Prophet'
layout: post
date: 2024-12-08
tags: [machine learning,statistics,case study]
pin: true
math: true
published: true
lang: en
---

In this article, I will show how we can make a model similar to the one provided by the [Prophet](https://facebook.github.io/prophet/docs/quick_start.html)
library and how we can tweak it to make it even better. 

I have used Prophet in several of my work projects when dealing with time series
and I like its ease of use while being kinda general purpose.
It has decent predictive power, is fast to train and is well interpretable.
But it has its downsides. 
I mentioned in the [article about generalized linear models](/posts/glms)
that a case where least squares methods fail is when the data are positive integers close to zero.
The same is true for Prophet which is actually kinda just regularized least squares. 
Here, I explain how we can DIY code its seasonality modelling with [Stan](https://mc-stan.org/),
that Prophet also uses as an engine.

I used a similar technique in the [inhomogeneous Poisson process](/posts/inhomogeneous-poisson-process/), but here I focus on use with GLMs.

## Modelling periodicity 
One of the main selling points of Prophet is the ability to model seasonality nicely.
We have seen in the previous [GLM](/posts/glms) article simple model which has weekly seasonality
expressed by an indicator feature for weekend, which was one parameter. 
If you have data over many weeks, you can probably expend seven parameters to learn a coefficient
for each one–hot encoded weekday.
But you probably don't have daily data going for millennia to use the same technique for yearly seasonality.
If we have finer granularity in the time series, such per hour or per minute, we may also want to model daily seasonality.
Or, maybe you want to test the hypothesis that the Lunar cycle has an effect on the outcome of your measurements.
We need something else to model these, and we take inspiration in Fourier series.
Remember, that a periodic function $f: \mathbb{R}\to\mathbb{R}$ with period $T$ (year, day, ...) can be represented as:

$$\begin{equation} f(t\,|\,\alpha,\beta) = \alpha_0 + \sum_{k=1}^{\infty} \left( \alpha_k \cos\frac{2 \pi k t}{T} + \beta_k \sin\frac{2 \pi k t}{T} \right) \label{fourier}\end{equation}$$


In classical analysis, $f$ is given, and we want to solve for $\alpha,\beta$ to obtain the series. 
Here the idea is, that there is an underlying but unknown $f$ which transforms the feature expressing time,
and we take a $K$th partial sum of the series to approximate it 
and learn its parameters  $\alpha,\beta$ from data ($\alpha_0$ will usually be redundant in practice).
For each periodicity we want to model, we can do this independently with different $T,K$. 
The parameter $K$ is the one called `fourier_order` in Prophet.

Now assume that we already have a feature matrix, with a column $t$ representing time.

$$ X =  \begin{bmatrix}1 & x_{11} & \cdots & x_{1m} & t_1 \\ \vdots & \vdots & \ddots & \vdots & \vdots \\ 1 & x_{n1} & \cdots & x_{nm} & t_n\end{bmatrix} $$

Since our parametrization of the Fourier series is some linear combination of the sines and cosines 
(unlike the more intuitive phase-amplitude parametrization of Fourier series),
we can just include these as extra features:

$$ X' = \begin{bmatrix} X & f(t\,|\,\alpha,\beta)\end{bmatrix} = \begin{bmatrix}1 & x_{11} & \cdots & x_{1m} & \cos \frac{2\pi 1 t_1}{T} & \sin \frac{2\pi 1 t_1}{T} &  \cdots & \cos \frac{2\pi K t_1}{T} & \sin \frac{2\pi K t_1}{T} \\ \vdots & \vdots & \ddots & \vdots & \vdots &  \vdots & \ddots & \vdots & \vdots \\ 1 & x_{n1} & \cdots & x_{nm} & \cos \frac{2\pi 1 t_m}{T} & \sin \frac{2\pi 1 t_m}{T} &  \cdots & \cos \frac{2\pi K t_m}{T} & \sin \frac{2\pi K t_m}{T}\end{bmatrix} $$

We then plug this into whatever GLM. This is thus a special case of the basis function regression method, which is pretty standard, so this is no rocket science, but I intend to develop this idea further in future articles.

For example, the simplest GLM (normal–identity) is the OLS model:

$$ y \sim \mathrm{Normal}\left(X'\theta, \; \sigma^2\right)$$

We can then extract the values $\alpha,\beta$ by looking at the corresponding positions in the vector $\theta$.
This can be done for multiple seasonalities simultaneously. We may also represent the weekly seasonality like this,
so that instead of the 7 parameters for the one-hot encoding, we may only fit 2,4 or 6 parameters (for $K \in  \{1, 2, 3\}$).
This may help reduce overfitting, but also implicitly introduces an assumption of some sort of continuity between the successive days, 
which may not be accurate when e.g. weekend is very different from workdays.

This is essentially what Prophet does. However, we don't have to limit ourselves to the Normal-Identity GLM.
For things like counts of purchases (especially low counts),  a discrete distribution based GLM will be more appropriate.

## Alternative parametrizations
A bit funky variation of the above can be done using complex numbers.

The series expansion $\eqref{fourier}$ can be also written as:

$$\begin{equation} f(t\,|\,\zeta) = \sum_{k=-\infty}^{\infty} \zeta_k\exp\frac{i 2 \pi k t}{T} \label{fourier_complex}\end{equation}$$

where $\zeta_k \in \mathbb{C}$.

However, when $f: \mathbb{R} \to \mathbb{R}$ (which is almost always the case in time series analysis practice),
there is some redundancy in the sense that $\zeta_{-k} = \bar{\zeta_k}$ and thus also $\mathrm{Im}(\zeta_0)=0$. We thus still need to only fit the parameters
for $k \ge 0$, and we alternatively specify it as follows:

$$\begin{equation} f(t\,|\,\zeta) = \mathrm{Re}\left(\sum_{k=0}^{\infty} \zeta_k\exp\frac{i 2 \pi k t}{T}\right) \label{fourier_complex_re}\end{equation}$$

While this is elegant in a certain way, it may be somewhat clunkier to use explicitly in a model implementation, especially when talking about GLMs. 

Then there is also the amplitude-phase form of the Fourier series:

$$\begin{equation} f(t\,|\,A,\varphi) = A_0 + \sum_{k=1}^{\infty} A_k\cos\left(\frac{2 \pi k t}{T} - \varphi_k\right) \label{fourier_amp_phase}\end{equation}$$

This may have a more intuitive interpretation but is not linear in $A, \varphi$ and also when $A_k = 0$ then the value of $\varphi_k$ is irrelevant and the parameter values are bounded.
These facts make this parametrization incompatible with GLM and generally unfriendly for numerical optimization.

