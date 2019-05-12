#' second_modulo
#' @export

second_modulo <- function(x) round(lubridate::second(Sys.time())) %% x

#' expr
#' @export

expr <- rlang::expr(map_lgl(1:3, ~{cat(".") ; Sys.sleep(1) ; return(second_modulo(5) == 0)}))
