# B2BDC-PiecewiseModels

What are Piecewise Models for B2BDC?
============
* Piecewise surrogate models is a class for B2BDC which constructs polynomial surrogate models on disjoint portions of a domain
* Provides heuristic to subdivde domains 
* Subdomains which have large fitting error, but can still be proven incompatible with the experimental evidence, are neglected
* Utilization of experimental evidence enables an increased efficiency, sampling regions where models and data agree 
	* Number of evaluations of the underlying model can be reduced considerably compared to traditional piecewise surrogate modeling strategies

How does the class work? 
============
The Piecewise models class is an extension to the Bound-to-Bound Data Collaboration toolkit. 
Methods and objects were tested with commit [e9d501a](https://github.com/B2BDC/B2BDC/commit/e9d501a4d89600b83c1e7cda2306ef006d23d76f)

Installation 
============
* Copy ```piecewiseOptions.m``` into the root directory of the B2BDC Toolkit, i.e., ```+B2BDC/```
* Copy the folder ```@PiecewiseModel``` into the directory  ```+B2BDC/+B2Bmodels/```


Methods
============
```
findModelIndex
eval
length
rule
inDomain
grow
extractData
fitSubDomain
consistentDomains
branch
```
