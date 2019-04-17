# get_current_ip
#' @export
get_current_ip <- function(){
  ip <- xml2::read_html("http://geoip.hmageo.com/ip/") %>% rvest::html_text()

  return(ip)
}

# disconnect_all
#' @export

disconnect_all <- function(force = F){
  cisco_disconnect(force = force)
  openvpn_disconnect()
}


#' success_connection
#' @export

successful_connection <- function(sucess){
  if(success){
    self$status <- "connected"
    self$ip <- get_current_ip()
    private$init_time <- Sys.time()
  }
}

#' list_all_connections
#' @export

list_all_connections <- function(){

  pref <- fs::path_expand("~")
  vpn_dir <- paste(pref, ".vpn", sep = "/")

  .path <- fs::dir_ls(vpn_dir) %>%
    str_subset(".Rdata")

  .id <- .path %>%
    str_remove(vpn_dir) %>%
    str_remove_all("/") %>%
    str_remove(".Rdata")

  return(tibble(.id, .path))
}

#' vpn_dir
#' @export

vpn_dir <- function(){
  pref <- fs::path_expand("~")
  vpn_dir <- paste(pref, ".vpn", sep = "/")
  return(vpn_dir)
}

#' get_connection
#' @export

get_connection <- function(id){

  path <- list_all_connections() %>%
    filter(.id == id) %>%
    pull(.path)

  tunnel <- get(load(path))

  return(tunnel)
}

