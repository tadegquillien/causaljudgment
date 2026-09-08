# ns(): compute a judgment with the NS model.

This function computes a NS judgment on the basis of a probability
distribution over counterfactual worlds

## Usage

``` r
ns(var, outcome, actual_world, d, causal_model)
```

## Arguments

- var:

  Character string giving the candidate cause variable.

- outcome:

  Character string giving the outcome variable.

- actual_world:

  A named list specifying the values of variables in the actual world.

- d:

  The dataframe containing the probability distribution over
  counterfactual worlds.

- causal_model:

  A named list specifying the causal model.

## Value

A numeric causal judgment.
