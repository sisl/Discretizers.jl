Discretizers
============

This package supports discretization methods and mapping functions.

* `CategoricalDiscretizer` maps between discrete values

* `LinearDiscretizer` maps from continuous values to discrete bins

[![Build Status](https://travis-ci.org/tawheeler/Discretizers.jl.svg?branch=master)](https://travis-ci.org/tawheeler/Discretizers.jl)

## Installation

Install the package using a clone call from within Julia:

```julia
Pkg.clone("https://github.com/tawheeler/Discretizers.jl.git")
```

## Use

Construct a `LinearDiscretizer` type mapping floats to Uint8 bin indeces:

```julia
bin_edges = [0.0, 0.5, 1.0, 2.0]
disc = LinearDiscretizer(bin_edges)
nlabels(disc) -> 3
```
  
The primary interface is *encoding* and *decoding*:

```julia
encode(disc, 0.25) -> 0x01
encode(disc, [0.2, 1.5, 0.2]) -> [0x01, 0x02, 0x01]
decode(disc, uint8(1)) -> rand(0.0:0.5)
```

Decoding currently samples informally from the given bin

Discretizers supports several discretization algorithms, including:

* uniform width discretization
* uniform sample count discretization
* MODL bayes-optimal binning for continuous features over a discrete target

These are all accessed using the `binedges()` function

```julia
nbins = 2
edges = binedges(DiscretizeUniformWidth(nbins), [0.0, 0.2, 0.1, 1.0, 0.6]) -> [0.0, 0.5, 1.0]
```

## Support

For questions please contact the package creator or create an issue

Feel free to create pull requests to improve the package
