#' novpn_init
#' @export
novpn_init <- function(dir = getwd()){
  fs::dir_create(glue::glue("{dir}/novpn"))
  download.file("https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip", glue::glue("{dir}/novpn/ovpn.zip"))
  zip::unzip(glue::glue("{dir}/novpn/ovpn.zip"),exdir = glue::glue("{dir}/novpn"))
}

#' novpn_get_configs
#' @export
novpn_get_configs <- function(dir = getwd()){
  config_dir <- fs::path_expand(glue::glue("{dir}/novpn/ovpn_tcp/"))
  
  config <- dir(config_dir, full.names = T)
  
  return(config)
}

#' novpn_new_tunnnel
#' @export
novpn_new_tunnnel <- function(config){
  openvpn_tunnel$new(config_file = readLines(stringr::str_split(config, "\n")[[1]]))
}