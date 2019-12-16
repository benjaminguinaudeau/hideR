pacman::p_load(tidyverse, glue, rlang, furrr, rvest, keyring, hideR)

# if(is.null(config_path)){config_path = "D:/Projects/git_proj/hideR/USA.Alabama.Montgomery.UDP.ovpn"}

# config_path <- "~/Downloads/utorvpn.ovpn"
#config_path <- "~/.vpn/utorvpn.ovpn"


vpn <- openvpn_tunnel$new(config_path = config_path)
# check if vpn_dir exists
connect_env <- current_env()

# taskkill.exe /F /IM openvpn.exe
vpn$connect(authentification = T, quiet = F, time_out = 10, prune_password = F, username = "favoone", password = "Ak-7V5tFichrJR8")
