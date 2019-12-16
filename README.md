# hideR <img src="man/figures/hideR2.png" width="160px" align="right" />

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental) [![](https://img.shields.io/github/languages/code-size/benjaminguinaudeau/hideR.svg)](https://github.com/benjaminguinaudeau/hideR) [![](https://img.shields.io/github/last-commit/benjaminguinaudeau/hideR.svg)](https://github.com/benjaminguinaudeau/hideR/commits/master)

# To do

  - unit testing for run\_as\_long\_as
  - Using Hide My Ass with R

This package aims at providing an interface to handle vpn connexion from
R. It proposes wrapper for openvpn connexion and specifically for : +
Vpn server offered by vpngate + Any VPN set up with Tunnelblick + Hide
My Ass Services + VPN Tunnels powered by cisco.

So far, it only works on mac OS.

# Installation

## Installing Openvpn

Before using hideR, you need to make sure that openvpn is install. To
install it, run

``` bash
brew update
brew install openvpn
```

``` bash
sudo apt-get update
sudo apt-get install openvpn
sudo apt-get install libxml2-dev
sudo apt-get install libsodium-dev
```

Make sure that openvpn is well installed by typing in Terminal.

``` bash
openvpn --help
```

If a long list of potential argumets appears, then it is good installed.
If you get an error saying (“openvpn: command not found”), please run:

``` bash
export PATH=$(brew --prefix openvpn)/sbin:$PATH
```

## Installing hideR

To install hideR, please run :

``` r
devtools::install_github("rstudio/rstudioapi")

fs::dir_create(vpn_dir())
devtools::install_github("benjaminguinaudeau/bashR", force = T)
devtools::install_github("benjaminguinaudeau/hideR")

bashR::sudo("ls", intern = T)
```

# Openvpn

## VPN with config file

### General Connexion

The most common way, to connect to a OpenVPN tunnel is to use a config
file (usually ending with .ovpn). If you have a config file, then you
can simply run :

``` r
config_path <- "path/to/my/config/file"

config_path <- "~/Downloads/utorvpn.ovpn"
#config_path <- "~/.vpn/utorvpn.ovpn"

# Initialize Connection according to configuration path

vpn <- openvpn_tunnel$new(config_path = config_path)
# check if vpn_dir exists

# For many VPN, no authorentifications is required
connect_env <- current_env()

vpn$connect(authentification = T, quiet = T, time_out = 10)

# You can access some detils about vpn
vpn$status
vpn$id
vpn$ip
vpn$running_time()

# At any point, you can check your IP address using
get_current_ip()

# Once you done, disconnect the VPN Tunnel with
openvpn_disconnect()
```

### Case where username and password are needed

Some VPN connexion requires password authentification. To do so, a line
in the config file has to point toward a local txt file containing
username and password.

The following function adds this line and create the txt file containing
the username and the password in the same directory as the config\_file.
Please note here that this txt file can be red by anybody, who has
access to the directory where your config\_file is located. So, choose
well this directory.

``` r
# Error to detect
#Exiting due to fatal error

# If you're vpn requires authentification: type the username and password
vpn$connect(authentification = T, quiet = T)
vpn$disconnect()

# If you registered a wrong password and you want to replace it
vpn$connect(authentification = T, prune_password = T, quiet = T)
```

## Saving VPN-Connections so that you can restart it later

``` r
# If you want to keep the connexion initialized for further use, save the object
vpn$save()

# To get a list of all your saved connexions
list_all_connections()

# If you want to load an saved connexion, give its id
vpn <- get_connection(id = "utorvpn")
# Then you can connect the new tunnel
vpn$connect(authentification = F, quiet = F)
vpn$disconnect()
```

# Importing config file from Tunnelblick

If you have been using Tunnelblick vor your vpn connexion, you can also
get direct access to the configuration informations. To do so, you can
access to the config file in Tunnelblick through (Configuration, Choose
the vpn you want to know the config file, Click on the Gear Icon, Modify
Config File).

Once you have the Config File, you can use copy the content and generate
a config file using

``` r
configurations <- "This is a very long string giving the content of the config files copied from Tunelblick
dev tun
proto udp
topology subnet
verb 3"

configurations <- rstudioapi::showPrompt("Config File", "Please Paste your Config File")

configurations %>%
  str_detect("\n")

vpn <- vpn_tunnel$new(config_file = str_split(configurations, "\n")[[1]])

vpn$connect(quiet = F)

openvpn_disconnect()
```

# Cisco Functions

Many VPN prefers to use cisco products. In this case, you’ll need to
authentificate. The procedure is the same.

``` bash
sudo apt-get install openconnect
```

``` r
vpn_cisco <- cisco_tunnel$new()
vpn_cisco$connect()

vpn_cisco$status
vpn_cisco$ip
vpn_cisco$running_time()

vpn_cisco$connect() #Reconnect
get_current_ip()
cisco_disconnect(force = T)
vpn_cisco$disconnect()
```

# VPN Gate

If you want to spare the time looking for a config file, you can also
rely on the database proposed by vpngate

``` r
servers <- vpngate_update_list()

servers %>%
  count(country_long, sort = T)

vpn_brazil <- vpngate_select(servers, c("country_long" = "Malaysia"))
vpn_brazil$connect(quiet = F)
vpn_brazil$disconnect()

fastest_server <-  servers %>%
  arrange(-speed) %>%
  slice(2)

vpngate_fast <- vpngate_select(servers, c('ip' = fastest_server$ip))

vpngate_fast$connect(authentification = F, quiet = F, time_out = 40)
```

# Hide My Ass

``` r
page <- xml2::read_html("https://vpn.hidemyass.com/vpn-config/UDP/")
nodes <- page %>%
  rvest::html_children() %>%
  rvest::html_children() %>%
  .[5] %>%
  rvest::html_children() %>%
  tail(-1) %>%
  map(rvest::html_attr, "href") %>%
  reduce(c)

data <- tibble(name = nodes, 
               link = paste0("https://vpn.hidemyass.com/vpn-config/UDP/", nodes)) %>%
  separate(name, sep ="\\.", into = c("country", "city", "type", "final", "a"), remove = F) %>%
  mutate(state = ifelse(is.na(a), NA_character_, city),
         city = ifelse(is.na(a), city, type), 
         type = ifelse(is.na(a), type, a))  %>%
  select(country, state, city, type, link)

config_file <- data %>%
  filter(country == "Germany") %>%
  slice(1) %>%
  pull(link) %>%
  readLines()

vpn <- openvpn_tunnel$new(config_file = config_file)
# check if vpn_dir exists

# For many VPN, no authorentifications is required
connect_env <- current_env()
vpn$connect()
```

``` r
library(tidyverse)

config_path <- "~/Downloads/vpn-configs/UDP/France.Paris.UDP.ovpn"
vpn <- openvpn_tunnel$new(config_path = config_path)

env_to_import <- rlang::new_environment()
env_to_import[["vpn"]] <- vpn

vpn <- bashR::run_as_job(
  import_global = F,
  env_to_import = as_environment(vpn),.command = ~{
    env_to_import$vpn$connect(authentification = T,  username = "bguinaudeau", password = "") 
    out <- env_to_import$vpn
    })

vpn$status
vpn$ip
vpn$disconnect()
disconnect_all(force = T)
```
