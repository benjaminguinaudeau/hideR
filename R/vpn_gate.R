
#' vpngate_update_liste
#' @export

vpngate_update_list <- function(){
  message("This might takes a few seconds...")

  # Updating csv file
  if(fs::file_exists("./config/meta_data.txt")){
    fs::file_delete("./config/meta_data.txt")
  }

  run_as_long_as(
    expr = download.file("https://www.vpngate.net/api/iphone/", "./config/meta_data.txt"),
    output_cond = fs::file_exists("./config/meta_data.txt"),
    max_iter = 5,
    time_out = 20,
    quiet = F
  )

  data <- read_csv("./config/meta_data.txt", skip = 1) %>%
    janitor::clean_names()

  server_list <- data %>%
    mutate(config_string = open_vpn_config_data_base64 %>%
             map(base64enc::base64decode) %>%
             map_chr(rawToChar))

  return(server_list)
}

#' vpngate_select
#' @export

vpngate_select <- function(server_list, criteria){
  config <- server_list %>%
    #rename_all(~str_remove(.x, "\\.")) %>%
    .[server_list[,names(criteria)] == criteria,] %>%
    drop_na(ip) %>%
    pull(config_string) %>%
    str_split("\r|\n") %>%
    .[[1]] %>%
    discard(~.x == "") %>%
    str_squish

  return(vpn_tunnel$new(config_file = config))
}
