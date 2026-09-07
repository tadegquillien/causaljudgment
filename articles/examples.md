# Examples

## Introduction

Here we give examples of model predictions for causal judgments in a
variety of scenarios. Some scenarios are drawn from the cognitive
science literature on causal judgment, some scenarios are there for
illustrative purposes (as of this writing some of these predictions have
not yet been tested!).

## Getting started

``` r

# load the package
library(causaljudgment)
```

## First example: simple conjunctive and disjunctive structures

### Conjunctive structure

Alice will graduate if she passes both her History AND her Math exam.
The Math exam is very difficult and the History exam is very easy. She
passes both exams and graduates. Did she graduate because she passed the
Math exam or because she passed the History exam?

Define the causal model and state of the actual world:

``` r

# exogenous probabilities
p_math <- .1 # probability of passing math exam
p_history <- .9 # probability of passing history

# structural equation
causal_rule <- 'history & math' # Alice passes if she passes history and math

# collect the above information in a causal model
causalmodel <- list(graduate=causal_rule, math=p_math, history=p_history)

# what happened in the actual world
actual_world <- list(graduate=1, math=1, history=1)
```

Compute causal judgment for History and Math:

``` r

# to what extent did passing the history exam (high-probability event) cause 
# Alice to graduate?
compute_judgment(
  'history', 'graduate', causalmodel, actual_world, 'ces', .7
  )
#> [1] 0.2739082

# to what extent did passing the math exam (low-probability event) cause 
# Alice to graduate?
compute_judgment(
  'math', 'graduate', causalmodel, actual_world, 'ces', .7
  )
#> [1] 0.9472197
```

Judgment is higher for the low-probability event; this reproduces a
classic effect in human judgments called ‘abnormal inflation’
(e.g. Morris et al., 2019; Kirfel et al., 2022).

### Disjunctive structure

This scenario is the same as above, except that Alice needs to pass
either the Math exam OR the History exam in order to graduate:

``` r

# new structural equation
disjunctive_rule <- 'history | math'
# causal model
causalmodel_disjunctive <- list(graduate=disjunctive_rule, history=p_history,
                                 math=p_math)

# to what extent did passing the history exam (high-probability event) cause 
# Alice to graduate?
compute_judgment(
  'history', 'graduate', causalmodel_disjunctive, actual_world, 'ces', .7
  )
#> [1] 0.513847

# to what extent did passing the math exam (low-probability event) cause 
# Alice to graduate?
compute_judgment(
  'math', 'graduate', causalmodel_disjunctive, actual_world, 'ces', .7
  )
#> [1] 0.1485895
```

Now judgment is higher for the high-probability variable! This effect is
called abnormal deflation, and was found in human participants by Icard
and colleagues (2017).

The Necessity-Sufficiency model also reproduces these effects:

``` r

# conjunctive structure
compute_judgment(
  'history', 'graduate', causalmodel, actual_world, 'ns'
  )
#> [1] 0.19
compute_judgment(
  'math', 'graduate', causalmodel, actual_world, 'ns'
  )
#> [1] 0.99

# disjunctive structure
compute_judgment(
  'history', 'graduate', causalmodel_disjunctive, actual_world, 'ns'
  )
#> [1] 0.9
compute_judgment(
  'math', 'graduate', causalmodel_disjunctive, actual_world, 'ces', .7
  )
#> [1] 0.1485895
```

## Experiments in Quillien & Lucas (2023)

Quillien & Lucas (2023) demonstrated that the details of what happened
in the actual world have an effect on people’s causal judgments. Here we
reproduce model predictions for their Experiment 2.

In that experiment, E happens if at least two of A,B,C happen. A, B and
C are low-, medium- and high-probability events.

``` r

causal_model <- list(e='a+b+c>1.5', a=.05, b=.5, c=.95) 
```

In study 2a, all three cause events happen. In study 2b, only A and B
happen:

``` r

actual_world2a <- list(e=1, a=1, b=1, c=1) # study 2a
actual_world2b <- list(e=1, a=1, b=1, c=0) # study 2b
```

In study 2a, participants favored the medium-probability variable B:

``` r

# A (low probability)
compute_judgment('a', 'e', causal_model, actual_world2a, 'ces', s=.7)
#> [1] 0.3389562
# B (medium probability)
compute_judgment('b', 'e', causal_model, actual_world2a, 'ces', s=.7)
#> [1] 0.4868692
# C (high probability)
compute_judgment('c', 'e', causal_model, actual_world2a, 'ces', s=.7)
#> [1] 0.1987486
```

In study 2b, they preferred the low-probability variable A:

``` r

# A (low probability)
compute_judgment('a', 'e', causal_model, actual_world2b, 'ces', s=.7)
#> [1] 0.6454083
# B (medium probability)
compute_judgment('b', 'e', causal_model, actual_world2b, 'ces', s=.7)
#> [1] 0.4649632
```

## Confounded models

### Simple confounded model

In the model E $`\leftarrow`$ A $`\rightarrow`$ C, C and E are
correlated, but C is not a cause of E. We check that the CES model makes
the appropriate prediction.

Define causal model and actual world:

``` r

causal_model <- list(e='a', a=.9, c='a')
actual_world <- list(e=1, a=1, c=1)
```

Check that we judge A, but not C, to cause E:

``` r

# A: 
compute_judgment('a', 'e', causal_model, actual_world, 'ces', s=.7)
#> [1] 1
# C:
compute_judgment('c', 'e', causal_model, actual_world, 'ces', s=.7)
#> [1] 0
```

### More complicated confounded model

In this model, we have C $`\rightarrow`$ E $`\leftarrow`$ A, and A
$`\rightarrow`$ C $`\leftarrow`$ B. That is, C has some causal effect on
E but the relationship between C and E is confounded by the fact that A
is a cause of both.

``` r

causal_model <- list(e='a | c', c='a | b', a=.5, b=.5)
```

We first look at a world where A happened but B did not happen.
Intuitively, A is a stronger cause of E than C:

``` r

# actual-world values
actual_world_onePath <- list(e=1, a=1, c=1, b=0)

# A:
compute_judgment('a', 'e', causal_model, actual_world_onePath,
                 'ces', s=.7)
#> [1] 0.9099891
# C:
compute_judgment('c', 'e', causal_model, actual_world_onePath,
                 'ces', s=.7)
#> [1] 0.3652763
```

We then look at a world where both A and B happened. In this world, A
and C have approximately the same causal strength:

``` r

# actual-world values
actual_world_twoPaths <- list(e=1, a=1, c=1, b=1)

# A:
compute_judgment('a', 'e', causal_model, actual_world_twoPaths,
                 'ces', s=.7)
#> [1] 0.3611576
# C:
compute_judgment('c', 'e', causal_model, actual_world_twoPaths,
                 'ces', s=.7)
#> [1] 0.3835643
```

We modify the causal structure so that E happens if both A and C happen.
Now A is assigned a higher causal strength again:

``` r

causal_model <- list(e='a & c', c='a | b', a=.5, b=.5)
# A:
compute_judgment('a', 'e', causal_model, actual_world_twoPaths,
                 'ces', s=.7)
#> [1] 1
# C:
compute_judgment('c', 'e', causal_model, actual_world_twoPaths,
                 'ces', s=.7)
#> [1] 0.3362767
```

## Double prevention

In a case of double prevention, C causes E to happen, but U could
prevent E. D prevents the preventer U (hence the name
‘double-prevention’). People typically think that C is a stronger cause
of E than D is.

We first show that the CES model reproduces this effect:

``` r

# define exogenous probabilities
pc <- .5
pu <- .5 
pd <- .5
# define the causal model. R represents the event of successful prevention.
causal_model <- list(e='c & !r', r='u & !d', c=pc, u=pu, d=pd)
# define the actual world
actual_world <- list(e=1, u=1, c=1, r=0, d=1)

# CES judgment for C:
compute_judgment('c', 'e', causal_model, actual_world, 'ces', s=.7)
#> [1] 0.7117101
# CES judgment for D:
compute_judgment('d', 'e', causal_model, actual_world, 'ces', s=.7)
#> [1] 0.589353
```

O’Neill et al. (2022, 2025) found that the double-prevention effect can
be reversed by manipulating the probability of U and D. We reproduce
this effect in the CES model:

``` r

pc <- .5
pu_high <- .9 # increase p(U)
pd_low <- .1 # decrease p(D)
causal_model_newprobs <- list(e='c & !r', r='u & !d', c=pc, u=pu_high, d=pd_low)

# CES judgment for C:
compute_judgment('c', 'e', causal_model_newprobs, actual_world, 'ces', s=.7)
#> [1] 0.5450961
# CES judgment for D:
compute_judgment('d', 'e', causal_model_newprobs, actual_world, 'ces', s=.7)
#> [1] 0.7570712
```

Running the same model predictions with the NS model:

``` r


## with initial set of probabilities (all p=.5)
# NS judgment for C:
compute_judgment('c', 'e', causal_model, actual_world, 'ns')
#> [1] 0.875
# NS judgment for D:
compute_judgment('d', 'e', causal_model, actual_world, 'ns')
#> [1] 0.6666667

## with new set of probabilities
# NS judgment for C:
compute_judgment('c', 'e', causal_model_newprobs, actual_world, 'ns')
#> [1] 0.595
# NS judgment for D:
compute_judgment('d', 'e', causal_model_newprobs, actual_world, 'ns')
#> [1] 0.9473684
```

## Noisy-Disjunctive structure

Here we look at a noisy version of a disjunctive structure. E happens if
either A or B happens, but sometimes a causal variable may fail to
trigger E. For instance Alice and Billy throw a rock at a bottle (which
will break if either rock reaches the bottle) but each throw might miss.

We may have the intuition that the most reliable causal variable is the
cause, even if A and B happen with the same probability. I.e. if Billy
is more skilled at rock-throwing than Alice, the event of Billy throwing
the rock is a better cause of the bottle breaking than the event of
Alice throwing the rock (even if in the actual world both succeeded).

We first set up the model:

``` r

# define probabilities of A and B
pa <- .5 # Alice throws with .5 probability
pb <- .5 # Billy throws with .5 probability

# define reliability with which A and B trigger E
# we define new exogenous variables for that purpose
p_uae <- .6 # Alice's rock reaches bottle with .6 probability
p_ube <- .9 # Billy's rock reaches bottle with .9 probability

# the structural equation for E: E happens if A and U_a->e happen or if B and
# U_b->e happen
equation_e <- 'a&uae | b&ube'

# define the causal model
causal_model <- list(e=equation_e, a=pa, b=pb,
                     uae=p_uae, ube=p_ube)
```

Request CES causal judgments for A and B. We assume that we can see that
both causes were successful (e.g. that Alice and Billy both threw a rock
at the bottle, and that both rocks successfully reached the bottle).

``` r

# in the actual world, everything happens
actual_world <- list(e=1, a=1, b=1, uae=1, ube=1)
# CES judgment for A (less reliable cause):
compute_judgment('a','e',causal_model, actual_world, 'ces', .7)
#> [1] 0.2682245
# CES judgment for B (more reliable cause):
compute_judgment('b','e',causal_model, actual_world, 'ces', .7)
#> [1] 0.4245325
```

The CES model judges that Billy throwing the rock is a better cause of
the bottle breaking.

## Time

People tend to see recent events as more causally important than early
events. We can model the effect of time by assuming that people are more
likely to simulate alternatives to recent relative to early events.

We implement this by assuming that the stability parameter $`s`$ is
time-dependent (lower stability for recent events), as in Quillien et
al. (2025).

We first consider a basketball game where Alice and Billy end up winning
the game 2 to 1. Alice scored the first point and Billy scored the
second point. Claire (in the opposite team) scored sometime in between.

``` r

# exogenous probabilitiy of variables
pa <- .2 # p(alice scores)
pb <- .2 # p(billy scores)
pc <- .2 # p(claire scores)
pd <- .2 # p(denis scores)

# time step at which events happen
ta <- 1 # alice scores first
tb <- 3 # billy scores third
tc <- 2 # claire scores second


# function giving counterfactual stability as a function of time
compute_stability <- function(time){
  s_vector <- c(.7, .5, .3)
  return(s_vector[time])
}

# stability parameters 
s_list <- list(a=compute_stability(ta), b=compute_stability(tb), 
               c=compute_stability(tc), d=.5)

# condition for victory
equation_e <- 'a+b > c+d'

# define the causal model
gameModel <- list(e = equation_e, a = pa, b = pb,
                  c=pc, d=pd)

# the values of variables in the actual world
actual_world <- list(e = 1, a = 1, b = 1, c=1, d=0)
```

Compute causal judgment for A and B:

``` r

# CES judgment for A (early event):
compute_judgment(
  "a", "e", gameModel, actual_world, "ces", s_list
)
#> [1] 0.3902073
# CES judgment for B (late event)
compute_judgment(
  "b", "e", gameModel, actual_world, "ces", s_list
)
#> [1] 0.5234229
```

Billy scoring the second point is judged as a better cause of victory
than Claire scoring the first point.

Henne et al. (2021) showed that the temporal order effect is reversed in
a disjunctive structure (where either point would have been enough for
the team to win the game). In this version of the scenario, Alice and
Billy’s team wins the game 2 to 0:

``` r

# time step at which events happen
ta <- 1 # alice scores first
tb <- 2 # billy scores second

# stability parameters 
s_list <- list(a=compute_stability(ta), b=compute_stability(tb), c=.5, d=.5)

# the values of variables in the actual world
actual_world <- list(e = 1, a = 1, b = 1, c=0, d=0)

# CES judgment for A (early event):
compute_judgment(
  "a", "e", gameModel, actual_world, "ces", s_list
)
#> [1] 0.474478
# CES judgment for B (late event)
compute_judgment(
  "b", "e", gameModel, actual_world, "ces", s_list
)
#> [1] 0.4172687
```

Now Alice scoring the first point is the most important cause.

## References

Henne, P., Kulesza, A., Perez, K., & Houcek, A. (2021). Counterfactual
thinking and recency effects in causal judgment. *Cognition*, 212,
104708.

Icard, T. F., Kominsky, J. F., & Knobe, J. (2017). Normality and actual
causal strength. *Cognition*, 161, 80-93.

Kirfel, L., Icard, T., & Gerstenberg, T. (2022). Inference from
explanation. *Journal of Experimental Psychology: General*, 151(7),
1481.

Morris, A., Phillips, J., Gerstenberg, T., & Cushman, F. (2019).
Quantitative causal selection patterns in token causation. *PLoS One*,
14(8), e0219704.

O’Neill, K., Quillien, T., & Henne, P. (2022). A counterfactual model of
causal judgment in double prevention. *Conference in computational
cognitive neuroscience*.

O’Neill, K., Henne, P., Quillien, T., Icard, T., & DeBrigard, F. (2025).
Norms moderate causal judgments in cases of double prevention.
*Proceedings of the Annual Meeting of the Cognitive Science Society*
(Vol. 47).

Quillien, T., & Lucas, C. (2023). Counterfactuals and the logic of
causal selection. *Psychological Review*.

Quillien, T., O’Neill, K., & Henne, P. (2025). A counterfactual
explanation for recency effects in double prevention scenarios:
commentary on Thanawala and Erb (2024). *Cognition*, 106106.
