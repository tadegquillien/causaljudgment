### compute_judgment() ---------------------------------------------------------

#' compute_judgment(): compute a causal judgment.
#' 
#' The general causal judgment function. It is essentially a wrapper 
#' over the ces() and ns() functions.

#' @param var Character string giving the candidate cause variable.
#' @param outcome Character string giving the outcome variable.
#' @param causal_model A named list specifying the causal model.
#' @param actual_world A named list specifying the values of variables
#'   in the actual world. The names must match those in `causal_model`.
#' @param model Character string specifying the causal judgment model.
#'   Currently, `"ces"` and `"ns"` are supported.
#' @param s Numeric or Named List parameter(s) controlling the adjustment of 
#' exogenous variable probabilities toward their actual-world values. Defaults
#'   to `0`. Usually this is a scalar that applies to all variables in the 
#'   model, but one can also use a named list that specifies a separate
#'   parameter for each variable.
#'
#' @return A numeric causal judgment.
#' 
#' @examples
#' # Define a causal model
#' causal_model <- list(e = "a & b", a = .1, b = .9)
#'
#' # Define the actual world
#' actual_world <- list(e = 1, a = 1, b = 1)
#'
#' # Compute the CES judgment for A causing E
#' compute_judgment(
#'   var = "a",
#'   outcome = "e",
#'   causal_model = causal_model,
#'   actual_world = actual_world,
#'   model = "ces",
#'   s = .7
#' )

#'
#' @export
#' 
compute_judgment <- function(var, outcome, causal_model, actual_world, 
                             model, s=0){
  
  ## check for errors in data entry
  
  var_names <- names(causal_model) # extract variable names
  
  # check that names of variables and actual_world are the same
  if(!setequal(var_names, names(actual_world))){
    stop('error: variable names must match across lists.')
  }
  
  # check that no variable starts with 'p'
  for (n in var_names){
    if (substr(n,1,1)=='p'){
      stop('error: please do not use variable names starting with P.\n
           Please rename variable ', n, '.')
    }
  }
  # check that the target and outcome variables belong to the causal model
  if(!(var %in% var_names)){
    stop('error: cause variable is not defined in the causal model.')
  }
  if(!(outcome %in% var_names)){
    stop('error: outcome variable is not defined in the causal model.')
  }  
  
  ## compute causal score
  structural_functions <- make_function_list(causal_model) # create causal model
  # enter joint probabilities
  df <- compute_probabilities(structural_functions, actual_world, s) 
  
  # if model is CES, perturb the distribution so that C is independent
  #   (if C is endogenous)
  if(model=='ces'){
    # detect if C is endogenous
    fun <- structural_functions[[var]] # extract function for C
    args <- names(formals(fun)) # extract function arguments
    # if variable is endogenous
    if(length(args)>0){ 
      # compute marginal probability
      marginal_pvar <- sum((df[[var]]==actual_world[[var]])*
                             df[[paste('p', var, sep='')]]*df$p)
      # re-compute pc as the marginal probability
      df[[paste('p', var, sep='')]] <- ifelse(df[[var]]==actual_world[[var]], 
                                              marginal_pvar, 
                                              1-marginal_pvar)
      # re-compute p (the probability of each world) 
      colnumber <- ncol(df)
      df$p <- 0
      for(i in 1:nrow(df)){
        df[i,]$p <- prod(df[i, ((colnumber/2)+1):colnumber])
      }
    }
  }
  
  
  
  # select model and compute score
  if(model == 'ces'){
    score <- ces(var, outcome, actual_world, df)
  }
  if(model == 'ns'){
    score <- ns(var, outcome, actual_world, df, structural_functions)
  }
  return(score)

}

