#' os
#' @export

os <- function() Sys.info()['sysname']

# get_current_ip
#' @export
get_current_ip <- function(loc = F){
  tmp <- get_ip_info()
  if(loc){
    return(tmp)
  } else {
    return(tmp$ip)
  }
}

# disconnect_all
#' @export

disconnect_all <- function(force = F){
  cisco_disconnect(force = force)
  openvpn_disconnect()
}


#' success_connection
#' @export

successful_connection <- function(.success, self, private){
  if(.success){
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
  
  if(!fs::dir_exists(vpn_dir)){fs::dir_create(vpn_dir)}
  
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

#' ip_info
#' @export
get_ip_info <- function() {
  
  # devtools::install_github("wrathematics/getip")
  
  # getip_pos <- possibly(getip::getip, otherwise = "no ip")
  
  # current_ip <- getip_pos("public") %>% stringr::str_split(", ") %>% magrittr::extract2(1) %>% magrittr::extract(1)
  
  current_ip <- "no ip" 
  
  if (current_ip =="no ip" ) {
    current_ip <- xml2::read_html("http://geoip.hmageo.com/ip/") %>% rvest::html_text()
    
  }
  
  
  IPtoCountry::IP_location(IP.address = current_ip ) %>%
    dplyr::mutate(ip = current_ip) %>%
    dplyr::select(ip, everything()) %>%
    dplyr::mutate(reg_info = glue::glue("{abrv} {region}, {city}"))
}

#' #' get_current_location
#' #' @export
#' get_current_location <- function(){
#'   page <- xml2::read_html("https://www.whatismybrowser.com/detect/ip-address-location")
#'   
#'   page %>% 
#'     html_node("#detected_value") %>%
#'     html_text
#' }

