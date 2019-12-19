#' nord_vpn_init
#' @export
nord_vpn_init <- function(dir = getwd()){
  fs::dir_create(glue::glue("{dir}/nord_vpn"))
  download.file("https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip", glue::glue("{dir}/nord_vpn/ovpn.zip"))
  zip::unzip(glue::glue("{dir}/nord_vpn/ovpn.zip"),exdir = glue::glue("{dir}/nord_vpn"))
}

#' nord_vpn_get_configs
#' @export
nord_vpn_get_configs <- function(dir = getwd()){
  config_dir <- fs::path_expand(glue::glue("{dir}/nord_vpn/ovpn_tcp/"))
  
  config <- dir(config_dir, full.names = T)
  
  return(config)
}

#' nord_vpn_new_tunnnel
#' @export
nord_vpn_new_tunnnel <- function(config){
  openvpn_tunnel$new(config_file = readLines(stringr::str_split(config, "\n")[[1]]))
}