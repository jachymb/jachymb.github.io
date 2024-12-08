---
title: 'Parametrizing features'
layout: post
date: 2024-12-08
tags: [probability theory,statistics,case study]
pin: true
math: true
published: false
---

In this article, I will show how we can make a model similar to the one provided by the [Prophet](https://facebook.github.io/prophet/)
library and how we can tweak it to make it even better. 

I have used Prophet in several of my work projects when dealing with time series
and I like its ease of use while being kinda general purpose.
But it has its downsides. 
I mentioned in the [article about generalized linear models](/posts/glms)
that a case where least squares methods fail is when the data are positive integers close to zero.
The same is true for Prophet which is actually kinda just least squares on steroids. 
Here, I explain what I consider to be the main "steroids" and how we can DIY code it with [STAN](https://mc-stan.org/),
that Prophet also uses as an engine.

## foo
