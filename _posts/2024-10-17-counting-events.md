---
title: 'Counting events – how counting probability distributions arise'
layout: post
date: 2024-10-17
tags: [probabilistic modelling,time series,event series]
pin: true
math: true
---

In this article, I focus on the question, how many events occur within a time frame,
given a probabilistic model of the waiting times of successive events.

On the lowest level of temporal data, there are timestamps of events.
In the article on [waiting times](/posts/waiting-times) I explained some options how the distance between 
those can be modelled probabilistically.
These are however often pre-aggregated for analytic purposes, most commonly as counts of events per day.
This deserves a closer look.
A natural question to ask in such case is, what is the probability distribution of these counts?
This, at least in principle, can be answered by looking at the distribution of the waiting times 
and deriving the distribution of the counts from that.  

## Basic formalization - continuous time

Let's describe what does this mean formally. 
We still keep the i.i.d. assumption for now, but consider a general
probability distribution over $\mathbb{R}^+$ with density $p(t)$ describing 
the probability of waiting time. The waiting times are a sequence of random variables $Y_1,Y_2,...$.
Now, the time of the $k$-th event is:

$$S_k = Y_1 + Y_2 + ... + Y_k$$

We are interested in the number of events $N(T)$ that occur in the interval $(0,T)$. That is:

$$N(T) = \max \{ k | S_k < T \}$$

For further reference, this line of thinking is developed in the [renewal theory](https://en.wikipedia.org/wiki/Renewal_theory) which studies this as well
as other questions regarding $N(T)$.

## Probability of $k$ events

Consider that the $k$-th even must occur before $T$ and $(k+1)$-th event must occur after $T$.
We can write that down as an equation:

$$P(N(T) = k) = P(S_k < T \le S_{k+1}) = P(S_k < T, T \le S_{k+1})$$

Using the independence assumption we can break this into:

$$P(S_k < T, T \le S_{k+1}) = P(S_k < T) \cdot P(T \le S_{k+1})$$

The probability of the $k$-th event occurring before time $T$ is given by the cumulative distribution function (CDF)

$$F_k(T) = P(S_k < T)$$

and the probability of the $(k+1)$-th event is given by the complementary CDF. 
Putting this together, we obtain

$$\begin{equation}\label{eq:pnt}P(N(T) = k) = F_k(T) \cdot (1 - F_{k+1}(T))\end{equation}$$

This way, the problem of identifying $P(N(T)=k)$ can be reduced to identifying the cumulative density $F_k(T)$ for all $k$.
This however sometimes uses expensive-to-compute special functions even for the more usual distributions.

## Cumulative density of $S_k$
We could naturally ask: what is a more explicit formula for $F_k(T)$? I mentioned this in the previous article, but want to show it a bit more in detail here.

Obviously, for $F_1(T) = \int_0^T p(t) \mathrm{d}t$. Consider now that $S_2 = Y_1 + Y_2$ 
has an arbitrary realization where $S_2$ happens at time $t$, and $Y_1,Y_2$ happen at $y_1,y_2$ respectively.
We have $y_2 = t - y_1$. 
Since the events $Y_1, Y_2$ are assumed i.i.d., the probability density will be:

$$p_{S_2}(t) = p(y_1) \cdot p(t - y_1)$$

Summing over all possible times of $y_1$, we see that this is just convolution,
which is of course a special case of the theorem saying that density of sum of random variables is the convolution of the respective densities:

$$p_{S_2}(t) = \int_{-\infty}^{\infty} p(y_1) \cdot p(t - y_1) \mathrm{d}y_1 = (p \ast p)(t) $$

This logic can be applied inductively to obtain that $p_{S_k}(t) = p^{\ast k}(t)$ and thus:

$$F_k(T) = \int_0^T p_{S_k}(t) \mathrm{d}t = \int_0^T p^{\ast k}(t) \mathrm{d}t$$

## Special case for exponential distribution
![](/assets/images/exp_events_count.png "Counts of events with Exponential(1/3) waiting times for T=10")

The above approach is rather general and can be in principle used for any i.i.d. waiting times.
In the previous chapter, we have seen that the exponential distribution arises from 
a memorylessness assumption which may quite reasonable in practical modelling. 
Let's see what happens when we use this as the waiting time and plug it into the above results, that is $Y_i \sim \mathrm{Exponential}(\lambda)$.
Under this extra assumption, the renewal process is called (homogeneuous) [Poisson process](https://en.wikipedia.org/wiki/Poisson_point_process)
and here I show where the name comes from.

As a reminder, the density of the exponential distribution has a single parameter $\lambda$ and is given by:

$$p(t) = \lambda e^{-\lambda t}, \; t > 0$$ 

Convolving this density with itself produces:

$$p_{S_2}(t) = (p \ast p)(t) = \int_{0}^{t} \lambda e^{-\lambda y} \cdot \lambda e^{-\lambda (t-y)} \mathrm{d}y$$

The $y$s cancel out and we can simplify to

$$p_{S_2}(t) = \lambda^2 e^{-\lambda t} \int_{0}^{t} \mathrm{d}y = \lambda^2 e^{-\lambda t} \cdot t$$

Again, remembering that $\int_0^t t^{k-1} \mathrm{d}t = \frac{t^k}{k}$, this pattern can be inductively generalized to:

$$p_{S_k}(t) = \frac{1}{(k-1)!}\lambda^k t^{k-1} e^{-\lambda t}$$

Here, we may observe an interesting fact. This is density of a well-known distribution, the above is actually saying:

$$S_k \sim \mathrm{Erlang}(k, \lambda)$$

The [Erlang distribution](https://en.wikipedia.org/wiki/Erlang_distribution) has the CDF:

$$F_k = 1 - \sum_{i=0}^{k-1}\frac{1}{i!}\lambda^i e^{-\lambda}$$

Now by evaluating $\ref{eq:pnt}$ we get that:

$$P(N(T)=k) =  \frac{1}{k!} (\lambda T)^k e^{-\lambda T}$$

Which in this case is actually telling us that:

$$N(T) \sim \mathrm{Poisson}(\lambda T)$$

Et voilà! Going through this convoluted (pun intended) route, we eventually arrived 
at the good old familiar Poisson distribution probability mass function.

## General case?

There is a theorem<sup>[1]</sup> in renewal theory,
which says that the [probability generating function](https://en.wikipedia.org/wiki/Probability-generating_function) (PGF)
of the counts $G_{N(T)}$ is given by:

$$G_{N(T)}(z) = \mathcal{L}^{-1}\left(\frac{1-\varphi(r)}{r(1-z\varphi(r))}\right)(T),$$

where $\mathcal{L}^{-1}$ denotes the inverse Laplace transform 
and $\varphi(r) = \mathrm{E}[e^{-rY_i}] = \int_{-\infty}^{\infty} e^{-rt} p_{Y_i}(t)\mathrm{d}t$ is the Laplace transform of the waiting time probability density. 

Now this seems promising, obtaining $\varphi(r)$ is usually straightforward and getting the series expansion of the PGF is also not a huge problem.
(Mathematica can often do both.)
The challenge here is computing the inverse Laplace transform. 
This requires techniques of complex analysis even for the simplest cases and to my knowledge an analytic solution doesn't exist in most cases.

Only solution other than reproducing the exponential-Poisson relation (cool exercise btw) above that I was able to find for continuous time
was for the Erlang distribution (a special case of Gamma distribution), which is a sum of i.i.d. exponential waiting times, so it's a generalization.
In this case, when the waiting time is $\mathrm{Erlang(\alpha, \beta)}, \alpha \in \mathbb{N}, \beta \in \mathbb{R}^+$, then we get:

$$P(N(1)=k) = e^{-\beta} \sum_{m=0}^{\alpha-1}\frac{\beta^{k\alpha+m}}{(k\alpha+m)!}$$

and for general $N(T)$ we can just multiply $\beta$ by $T$.
I don't think this distribution has an established name.
Now, however, when we want to for example just generalize to Gamma distribution with $\alpha \in \mathbb{R}^+$,
the sum won't work anymore,
and we must (afaik) resort to the formula $\eqref{eq:pnt}$ and suffice with the much less computationally efficient formula,
which cannot really be simplified algebraically:

$$P(N(1)=k) = \frac{\Gamma(\alpha(1+k), \beta)}{\Gamma(\alpha(1+k))} - \frac{\Gamma(\alpha k, \beta)}{\Gamma(\alpha k)}$$ 

So although this theorem is deep, it doesn't seem immediately practical for this kind of analysis as I think a similar issue exists most distributions.

## Discrete time
We have seen in the previous chapter that for discrete time, 
the memoryless assumption implies that at each time unit we sample i.i.d.  $\mathrm{Bernoulli}(\theta)$ distribution
to see whether the event occurred or not.
It follows easily, that the number of events that happen within an interval of length $T$ 
has the $\mathrm{Binomial}(T, \theta)$ distribution.

When I was first taught about Poisson distribution, I was told it can be seen as a limit case of the Binomial distribution
in the sense that when keep $T \cdot \theta = \lambda$ fixed then for any $k \in \mathbb{N}$:

$$\lim_{(T,\theta)\to(\infty,0)} p_{\mathrm{Binomial}(T,\theta)}(k) = p_{\mathrm{Poisson}(\lambda)}(k) $$

In the context of using these two distributions to describe counts of events, this intuitively makes sense:
With discrete time model, with the granularity getting finer (time becoming more continuous),
$T$ grows for the same amount of physical time (more time units per interval of fixed duration)
and $\theta$ decreases (lesser probability of event occurring within a shorter window).

That also means we can use the simpler Poisson distribution as a good approximation when $\theta$ is low and $T$ is high,
for example when we want to count events per day and an event may be recorded at each second.

We can now summarize these analogies into the following table:

| Time model                      | Waiting time for next event<br>$Y_i$ | Waiting time for $k$-th event<br>$S_k$ | Count of events<br>$N(T)$      |
|---------------------------------|--------------------------------------|----------------------------------------|--------------------------------|
| Continuous $T \in \mathbb{R}^+$ | $\mathrm{Exponential}(\lambda)$      | $\mathrm{Erlang}(k, \lambda)$          | $\mathrm{Poisson}(T \lambda)$  |
| Discrete $T \in \mathbb{N}$     | $\mathrm{Geometric}(\theta)$         | $\mathrm{NegBinomial}(k, \theta)$      | $\mathrm{Binomial}(T, \theta)$ | 


### Takeaway
We derived the Poisson distribution as the count of events of a random process from nothing but the following assumptions:

* The events are i.i.d.,
* The waiting time between the events has a memoryless continuous random distribution.

Obtaining the distribution of counts of events for other waiting time distributions is possible in principle, at least numerically,
but usually won't have a nice closed-form solution.

Next read: [Inhomogeneous Poisson process](/posts/inhomogeneous-poisson-process/)

## References
1. Renewal Theory, D.R.Cox, 1962, p. 37
