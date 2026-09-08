
# ns model (icard, kominsky & knobe, 2017)

# the model computes the extent to which C=c caused E=e as:
# S(C=c->E=e)p(C=c) + N(C=c->E=e)(1-p(C=c))

# where S(C->E) is the sufficiency and N(C->E) the necessity, of C for E.
# N(C->E) is 1 iff intervening to set C to ¬c in the actual world would set
# E to ¬e
# S(C->E) = P(E==e|E=¬e, C=¬c, do(C=c))


### Counterfactual intervention computation ------------------------------------

# This function works recursively. Suppose Y depends directly on X: then the
# function can directly compute the effect of the intervention.
# But Y can also indirectly depend on X, for example via a chain X -> Z -> Y.
# To accommodate this kind of cases, we recursively call the 
# compute_counterfactual_value() function on intermediate values,
# until we reach X.


#' compute_counterfactual_value(): compute the value of Y conditioned
#' on a counterfactual intervention on X, starting from a given world.
#'
#' This function computes the value of Y conditioned
#' on a counterfactual intervention on X, starting from a given world. The 
#' function is used for computing both necessity and sufficiency.

#' @param intervention_var Character string: the variable we intervene upon
#' @param intervention_value Numeric: the post-intervention value of the 
#' variable we intervene upon
#' @param target_var Character string: the target variable. We want to compute 
#' the value it has after we've intervened on the intervention variable
#' @param causal_model A named list specifying the causal model
#' @param aw_values A named list with the values of the variables in the actual 
#' world
#' @return A numeric specifying the counterfactual value of the target variable.

compute_counterfactual_value <- function(intervention_var, intervention_value,
                                         target_var, causal_model, aw_values) {
  
  # if we're asking about the intervention variable itself, 
  # return intervention value
  if (target_var == intervention_var) {
    return(intervention_value)
  }
  
  # retrieve the function for the target variable
  target_function <- causal_model[[target_var]]
  
  # retrieve the arguments that this function expects
  target_args <- names(formals(target_function))
  
  # if function has no arguments (variable is exogenous), 
  # return value in the current world
  if (length(target_args) == 0) {
    return(aw_values[[target_var]])
  }
  
  # build argument list for the target function
  args_list <- list()
  # cycle through arguments
  for (arg in target_args) { 
    if (arg == intervention_var) {  # if the current argument is X
      args_list[[arg]] <- intervention_value   # assign intervention value
    } else { 
      # recursively compute counterfactual values for other arguments
      args_list[[arg]] <- compute_counterfactual_value(
        intervention_var, intervention_value, arg, causal_model, aw_values
      )
    }
  }
  # Call the function with the counterfactual arguments
  return(do.call(target_function, args_list))
}


### Necessity ------------------------------------------------------------------

#' compute_necessity(): compute whether X was necessary for Y in the actual 
#' world.
#' 
#' We check whether intervening on X in the actual world
#' flips the value of Y.
#' 
#' @param x_var Character string giving the candidate cause variable.
#' @param y_var Character string giving the outcome variable.
#' @param causal_model A named list of structural functions defining
#'   the causal model.
#' @param actual_world A named list giving the values of variables in
#'   the actual world.
#'
#' @return A logical value indicating whether the candidate cause is
#'   necessary for the outcome in the actual world.
compute_necessity <- function(x_var, y_var, causal_model, actual_world) {
  # get the actual-world values of X and Y
  x_actual <- actual_world[[x_var]]
  y_actual <- actual_world[[y_var]]
  
  # Create counterfactual world where we flip X
  x_counterfactual <- 1 - x_actual  # flip binary value
  
  # compute Y's value in the counterfactual world
  y_counterfactual <- compute_counterfactual_value(
    x_var, x_counterfactual, y_var, causal_model, actual_world
  )
  
  # X is necessary for Y if flipping X flips Y
  return(y_actual != y_counterfactual)
}


# example call
# causal_model <- list(e='a&z', a=.5, c = 'a', d='c', z=.5)
# causalmod <- make_function_list(causal_model)
# actual_world <- list(e=1, a=1, c=1, d=1, z=1)
# compute_counterfactual_value('e', 0, 'c', causalmod, actual_world)
# compute_necessity( 'a', 'e', causalmod, actual_world)
# compute_necessity( 'c', 'e', causalmod, actual_world)


### Sufficiency ----------------------------------------------------------------

# we will compute sufficiency by applying the formula:
# p(e=1|e=0,c=0,do(c=1)) = Sum_v p(e=1|V=v, do(c=1))p(V=v|e=0,c=0)
# where V is the set of all variables other than E and C

# (the proof of this formula is somewhat complicated, but basically we
# apply the law of total probability for conditional probability to marginalize
# over V, and then use the fact that p(E=1|V=v, E=0, C=0, do(C=1)) = 
# p(E=1|V=v, do(C=1)), which follows from the fact that E and C are 'screened 
# off' by V=v and by the intervention.)


#' compute_sufficiency(): computes the sufficiency of a candidate cause 
#' for an outcome. 
#' 
#' This function computes the sufficiency of a candidate cause 
#' for an outcome. 

#' @param var Character string giving the candidate cause variable.
#' @param outcome Character string giving the outcome variable.
#' @param actual_world A named list giving the values of variables in
#'   the actual world.
#' @param causal_model A named list of structural functions defining
#'   the causal model.
#' @param d A data frame containing the joint probability distribution
#'   over possible worlds.
#'
#' @return A numeric value representing the sufficiency of the candidate
#'   cause for the outcome.

compute_sufficiency <- function(var, outcome, actual_world, causal_model, d){
  
  ### step 1: compute p(V=v|c=0, e=0)
  
  # filter for worlds that have C=0, E=0
  base <- d %>% filter(!!sym(outcome)==1-actual_world[[outcome]],
                       !!sym(var)==1-actual_world[[var]])
  
  # select all other variables except for C and E
  other_vars <- names(d)
  other_vars <- setdiff(other_vars, c(outcome, var))
  # remove probability columns like 'p', 'pa', 'pb', etc.
  other_vars <- other_vars[!grepl("^p", other_vars)]  
  
  # compute P(V=v | e=0, c=0) by normalizing joint p
  base_ab <- base %>%
    group_by(across(all_of(other_vars))) %>%
    summarise(weight = sum(p), .groups = "drop") %>%
    mutate(weight = weight / sum(weight))
  
  ### step 2: compute p(e=1 |V=v, do(c=1))
  
  # initialize
  cf_probs <- base_ab 
  cf_probs$p_e1_cf <- NA_real_ 
  
  for (i in 1:nrow(cf_probs)) { # cycle through worlds with E=0, C=0
    row <- cf_probs[i, ] # select world
    
    # retrieve the variable values in the current world in list format
    current_world <- as.list(row[other_vars])
    # add the value of C and E (remembering that we conditioned on E and C 
    # having opposite values as in the actual world)
    current_world[[var]] <- 1-actual_world[[var]]
    current_world[[outcome]] <- 1- actual_world[[outcome]]
    
    # compute the value of E in the current world, given an intervention setting
    # C to its actual-world value
    cf_probs$p_e1_cf[i] <- compute_counterfactual_value(
      var, actual_world[[var]], outcome, causal_model, current_world
    )
    
  }
  
  ### step 3: compute final counterfactual probability by:
  ### -multiplying p(e=1|V=v, do(c=1)) and p(V=v)p(e=0, c=0) together
  ### -taking the sum across all values v of V
  sufficiency <- sum(cf_probs$weight * cf_probs$p_e1_cf)
  return(sufficiency)
  
}

# test
# causal_model <- list(e='a&z', a=.5, c = 'a', d='c', z=.5)
# causalmod <- make_function_list(causal_model)
# actual_world <- list(e=1, a=1, c=1, d=1, z=1)
# dtest <- compute_probabilities(causalmod, actual_world)
# compute_sufficiency('a', 'e', actual_world, causalmod, d=dtest)
# 
# # test with a chain structure
# causal_model <- list(e='z&c', z='a&b', a=.2, b=.6, d='a', c=.3)
# causalmod <- make_function_list(causal_model)
# actual_world <- list(e=1, z=1, a=1, b=1, d=1, c=1)
# dtest <- compute_probabilities(causalmod, actual_world)
# compute_sufficiency('a', 'e', actual_world, causalmod, d=dtest)


### full model: integrate necessity and sufficiency by weighing by p(c)---------
#' ns(): compute a judgment with the NS model.
#'
#' This function computes a NS judgment on the basis of a probability 
#' distribution over counterfactual worlds
#' @param var Character string giving the candidate cause variable.
#' @param outcome Character string giving the outcome variable.
#' @param actual_world A named list specifying the values of variables
#'   in the actual world. 
#' @param d The dataframe containing the probability distribution over 
#' counterfactual worlds.
#' @param causal_model A named list specifying the causal model.
#'
#' @return A numeric causal judgment.
#' 
#'
#' @export
#'
ns <- function(var, outcome,  actual_world, d, causal_model){
  # compute p(c) by filtering the df for C=aw(c), and summing across values of p
  pvar <- d %>% filter(!!sym(var)==actual_world[[var]]) %>% 
    summarize(s.p=sum(p)) %>% pull(s.p)
  # compute necessity-sufficiency score
  ns <- (1-pvar)*compute_necessity(var, outcome, causal_model, actual_world) + 
    pvar*compute_sufficiency(var, outcome, actual_world, causal_model, d)
  return(ns)
}

## example call
# 
# # setting things up
# conjunctiveModel <- list(e='a&b', a=.1, b=.9)
# disjunctiveModel <- list(e='a|b', a=.1, b=.9)
# actual_world <- list(e=1, a=1, b=1)
# causal_model_c <- make_function_list(conjunctiveModel)
# causal_model_d <- make_function_list(disjunctiveModel)
# df_c <- compute_probabilities(causal_model_c, actual_world)
# df_d <- compute_probabilities(causal_model_d, actual_world)

# # in a conjunctive model
# ns('a', 'e', actual_world, df_c, causal_model_c)
# ns('b', 'e', actual_world, df_c, causal_model_c)
# 
# # in a disjunctive model
# ns('a', 'e', actual_world, df_d, causal_model_d)
# ns('b', 'e', actual_world, df_d, causal_model_d)
