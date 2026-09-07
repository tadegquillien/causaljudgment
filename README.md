# causaljudgment

The <code>causaljudgment</code> package allows one to compute the predictions of computational models of causal judgment. Currently two models are implemented: the Counterfactual Effect Size (CES) model (Quillien & Lucas, 2023) and the Necessity-Sufficiency (NS) model (Icard, Kominsky & Knobe, 2017).

In this file, we give examples of how to compute causal judgments, describe current limitations, and then (for interested readers) give a high-level explanation of how these scripts work. More background about when and why to use this package is given [here](https://tadegquillien.github.io/causaljudgment/articles/background.html). For the original scientific papers see [here (CES)](https://quillienlab.github.io/Quillien%20&%20Lucas%202023.pdf) and [here (NS)](https://philpapers.org/archive/ICANAA.pdf).


### Getting started

First, install and load the package:

```r
install.packages("remotes")
remotes::install_github("tadegquillien/causaljudgment")
library(causaljudgment)

```

### How to use

Computing a causal judgment requires three steps:

-Specify a causal model,

-Specify what happened in the actual world,

-Request a causal judgment.

For example, suppose that Alice will graduate if she passes both her History 
and her Math exam. The Math exam is very difficult and the History exam is very
easy.

We specify this information as a causal model:

```r
p_math <- .1 # probability of passing math exam
p_history <- .9 # probability of passing history
causal_rule <- 'history & math' # Alice passes if she passes history and math
# collect the above information in a causal model
causalmodel <- list(graduate=causal_rule, math=p_math, history=p_history)
```

The string `'history & math'` specifies the structural equation for the 
`graduate` variable. The variables `history` and `math` each have an associated
prior probability.

Next specify what happens in the actual world; Alice passed both History and 
Math, and she graduates:

```r
actual_world <- list(graduate=1, math=1, history=1)
```


Finally we request a causal judgment:
```r
# to what extent did passing the math exam cause Alice to graduate?
compute_judgment('math', 'graduate', causalmodel, actual_world, 'ces', .7)
```

The first two arguments say that we want to see to what extent `math` 
caused `graduate`.
The next two arguments specify the causal model and the actual-world value of 
the variables (defined above). The fifth argument specifies the computational 
model we want to use (here, CES). The last argument specifies the value of the
stability parameter $s$ (how much counterfactual simulation is 'anchored' to 
the actual world). This argument is optional, by default $s=0$. 

Running this command will return a 'causal score' from -1 to 1 (for CES) or from 0 to 1 (for NS). Higher values indicate higher actual causal strength. For the CES model, a negative value like -.8 indicates a very weak causal score, not something like 'negative' causation. And -.8 is weaker than for example -.4.

More examples are provided in this [vignette](https://tadegquillien.github.io/causaljudgment/articles/examples.html).

References:

Icard, Kominsky & Knobe (2017). [Normality and actual causal strength](https://philpapers.org/archive/ICANAA.pdf). <i>Cognition</i>.

Quillien & Lucas (2023). [Counterfactuals and the logic of causal selection](https://quillienlab.github.io/Quillien%20&%20Lucas%202023.pdf). <i>Psychological Review</i>.

### Limitations

We currently only support causal models that have binary variables. The value of these variables must be input as 0 or 1. 

Structural equations must be specified as strings that use symbols that will be recognized by R as logical symbols. 
For example, `'a or not b'` will not work, but `'a | !b'` will. In principle it should be possible to express any Boolean function this way, although for some of them it might be cumbersome.

Causal models must be expressed as Structural Causal Models (SCMs). Non-deterministic models like Causal Bayes Nets are not supported, but one can always formulate an SCM that emulates a Causal Bayes Net by introducing 'noise' variables. See the 'Noisy-Disjunctive structure' in the vignette for an example.

On the positive side, any causal structure that can be expressed by an SCM with binary variables should be supported. This includes 'deep' chain structures like A $\rightarrow$ B $\rightarrow$ C $\rightarrow$ D $\rightarrow$ E, and confounded models where the effect of the cause C on the effect E is confounded by other variables.

### How the package works

We use an analytical approach to compute causal judgments for the CES and NS
models. For background on how these models work see the references above.

Our goal is to compute a causal judgment for the extent to which $C=c$ caused $E=e$. Instead of explicitly simulating counterfactual worlds by sampling
from the SCM, we analytically compute the probability distribution
over counterfactual worlds that would follow from this sampling process. This makes computation much faster.
First it is useful to describe what this sampling process would look like
(this will help understand what the analytical computation is trying to
formalize).

We sample each counterfactual world by doing the following:

1) Sample each exogenous variable according to the Lucas-Kemp process
(see Lucas & Kemp, 2015; Quillien & Lucas, 2023).

2) If $C$ is endogenous, sample the value of $C$ by making a random intervention
on $C$, where $C$ is sampled from $p(C)$. $p(C)$ is the marginal probability of $C$: it
is the probability we would get if we simply generated counterfactual worlds
without implementing step 2.

3) Determine the value of all other variables by applying the relevant
structural equations.

The distribution over counterfactual worlds that we wish to compute is the
relative frequency of worlds simulated this way, as the number of samples
goes to infinity.

To compute this probability distribution analytically, we do the following. We list each possible world (i.e. combination of variable values) as a row in a table. We then assign a probability to each world:

1) We compute the probability of each exogenous variable (defined by the Lucas-Kemp process).
   
2) For each endogenous variable $X$, we compute $p(X=x|\text{pa}(X))$ as 0 or 1, depending on whether $X=x$ is consistent with the value of the variable's parents (i.e. $\text{pa}(X)$ ) in the current world. (For example if we have $A := B$, and in the current world $A=1$ but $B=0$, then $p(B=0|\text{pa}(B))$ is 0). Note that since we are using SCMs with fully observed variables the conditional probabilities here are deterministic.
   
3) We compute a probability $p(w)$ for the whole world by using the factorization defined by the network structure, i.e. $p(w)=\prod_{V} p(V|\text{pa}(V))$. Note that if $V$ is exogenous then $p(V|\text{pa}(V)) = p(V|\emptyset) = p(V)$

4) If $C$ is an endogenous variable, we must perform an additional step to ensure that the distribution reflects the fact that $C$'s value is set by interventions. We first compute the marginal probability $p(C=c)$ in the distribution we just computed. Then we replace $p(C=c|\text{pa}(C))$ with $p(C=c)$ in every world. Doing this ensures that the probability of $C=c$ is now independent from the value of $C$'s parents, as required by the fact that $C$ is set by interventions. After doing this, we now re-compute the probability of each world.

After we have obtained the probability distribution over counterfactual worlds, it is easy to analytically compute the correlation between $C=c$ and $E=e$ in this distribution (for the CES model). We can also analytically compute Necessity and Sufficiency (for the NS model). See [here](https://tadegquillien.github.io/causaljudgment/articles/background.html#technical-description-of-the-model-implementations) for more details on these computations.

References:

Lucas & Kemp (2015). An improved probabilistic account of counterfactual reasoning. <i>Psychological Review</i>.

### Acknowledgments

This package would not exist without enthusiastic encouragement and advice from Joshua Knobe. I also thank Shubhamkar Ayare for raising an interesting technical point about CES implementation (see [here](https://tadegquillien.github.io/causaljudgment/articles/background.html#counterfactual-effect-size-model)).

### Citation
To cite the package in publications please use:

  Quillien T (2026). _causaljudgment: computational models
  of causal judgment_. R package.