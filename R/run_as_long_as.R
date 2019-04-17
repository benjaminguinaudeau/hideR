run_as_long_as <- function(.x = NULL,
                           expr,
                           input_cond = F,
                           output_cond = NULL,
                           max_iter = 1,
                           time_out = 0,
                           otherwise = NULL,
                           quiet = T){

  exec_env <- current_env()
  expression <- enexpr(expr)
  input_condition <- enexpr(input_cond)
  output_condition <- enexpr(output_cond)

  # Return input, if the input condition is met
  if(eval(input_condition)) return(.x)

  iter <- 0
  out <- NULL
  break_trig <- F
  if(is.null(output_condition)) output_condition <- F

  while(!break_trig){
    #browser()
    if(!quiet) message(glue("Iter # { iter }"))

    if(time_out == 0){
      exec_env$out <- try(eval(expression, envir = exec_env), silent = T)
    } else {
      exec_env$out <- try(
        R.utils::withTimeout(
          eval(expression, envir = exec_env),
          timeout = time_out,
          onTimeout = "silent"
        ),
        silent = T
      )
    }

    # Did the evaluation of the expression work?
    failure <- any(
      class(out)[1] == "try-error",
      is.null(out)
    )

    # If any of this condition is met, the while-loop should break
    break_trig <- any(
      eval(output_condition) & !failure,
      iter == max_iter
    )

    iter <- iter + 1
  }
  #browser()
  if(!eval(output_condition)){
    message("Output Condition could not be met.")
    out <- otherwise
  }
  if(iter == max_iter & !eval(output_condition)){
    message("Maximum Number of iteration was reached")
  }

  return(exec_env$out)
}
