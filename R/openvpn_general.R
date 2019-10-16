#' vpn_tunnel
#' @export

openvpn_tunnel <- R6::R6Class("openvpn_vpn",
                              inherit = hideR::vpn_tunnel,
                              private = list(
                                config_file = NULL
                              ),
                              public = list(
                                config_path = NULL,
                                initialize = function(
                                  config_path = NULL,
                                  config_file = NULL
                                ){
                                  
                                  if(is.null(config_path) & is.null(config_file)) stop("No Config Provided")
                                  if(!is.null(config_path)){
                                    self$config_path <- config_path
                                    
                                    private$config_file <- read_lines(config_path)
                                  } else {
                                    private$config_file <- config_file
                                  }
                                  
                                  #self$status <- "disconnected"
                                  
                                  self$id <- private$config_file %>%
                                    discard(str_detect, "^#") %>%
                                    keep(str_detect, "remote") %>%
                                    str_extract("\\s[^\\s]*\\.[^\\s]*(\\s|$)") %>%
                                    str_squish()
                                  
                                  if(is.null(config_path)) self$config_path <- glue::glue("{ vpn_dir() }/{ self$id }.ovpn")
                                  
                                  message(glue("VPN Tunnel { self$id } was initialized."))
                                },
                                save = function(){
                                  
                                  save_path <-  self$config_path %>%
                                    str_replace(".ovpn", ".Rdata")
                                  
                                  save(self, file = save_path)
                                },
                                disconnect = function(){
                                  openvpn_disconnect()
                                },
                                connect = function(
                                  authentification = F,
                                  prune_password = F,
                                  time_out = 20,
                                  quiet = T, 
                                  username = NULL, 
                                  password = NULL
                                ){
                                  config_path <- glue("{ vpn_dir() }/{ self$id }.ovpn")
                                  
                                  if(!authentification) {
                                    write_lines(private$config_file, config_path)
                                  } else {
                                    
                                    credential_path <- config_path %>%
                                      str_replace(".ovpn", "_pass.txt")
                                    if(is.null(username)){
                                      
                                      self$set_credentials(new_file = !fs::file_exists(credential_path) | prune_password,
                                                           credential_path = credential_path)
                                    } else {
                                      private$username <- username 
                                      private$password <- password
                                    }
                                    
                                    write_lines(c(private$username, private$password), credential_path)
                                    
                                    private$config_file %>%
                                      discard(~str_detect(.x, "auth-user-pass")) %>%
                                      c(paste0("auth-user-pass ", credential_path)) %>%
                                      write_lines(config_path)
                                  }
                                  
                                  success <- openvpn_connect(config_path, time_out = time_out, quiet = quiet)
                                  
                                  successful_connection(success, self = self, private = private)
                                }
                              )
)


#' openvpn_connect
#' @export

openvpn_connect <- function(config_path, time_out = 50, quiet = T, error_on_fail = F){
  config_path <- fs::path_expand(config_path)
  if(os()== "Windows"){config_path <- stringr::str_replace_all(config_path, "/", "\\\\")}
  openvpn_disconnect(2)
  
  if(!fs::file_exists(config_path)){
    stop("No config file, please check that you specified the right path to the config file")
  }
  
  
  .GlobalEnv$current_ip <- get_current_ip()
  message(glue("Current IP: { .GlobalEnv$current_ip }"))
  
  # shell <- rstudioapi::terminalExecute(
  #   command = glue("sudo /usr/local/sbin/openvpn --config { config_path } &"),
  #   show = T
  #   )
  
  cmd_openvpn <- case_when(os() == "Linux" ~ "openvpn", 
                           os() == "Windows" ~ stringr::str_replace_all("cd D:\\Program Files\\OpenVPN\\bin & openvpn", "/", "\\\\"), 
                           T ~ "/usr/local/sbin/openvpn")
  #/usr/local/sbin/openvpn
  if(os() != "Windows"){
    trash <- bashR::sudo(glue("{ cmd_openvpn } --config { config_path } &"), 
                         ignore.stderr = F,
                         ignore.stdout = F,
                         intern = F)
  } else {
    trash <- shell(glue('START /MIN { cmd_openvpn } --config { config_path } &'), 
                   ignore.stderr = F,
                   ignore.stdout = F,
                   intern = F, 
                   wait = T)
  }
  
  
  trash <- run_as_long_as(
    expr = {cat(".") ; Sys.sleep(1) ; return(".")},
    output_cond = .GlobalEnv$current_ip != get_current_ip(),
    max_iter = time_out
  )
  
  if(current_ip == get_current_ip()){
    openvpn_disconnect()
    cat("\n")
    if (error_on_fail) {
      stop("Connection could not be established")
    }
    message("Connection could not be established")
    return(F)
  } else {
    message(glue("Connection Successfull\n New IP: { get_current_ip() }"))
    return(T)
  }
}


#' openvpn_disconnect
#' @export


openvpn_disconnect <- function(time_out = 1, quiet = T){
  
  as.list(global_env()) %>%
    keep(~"vpn" %in% class(.x)) %>%
    map(~{
      .x$status <- "disconnected"
      .x$ip <- "disconnected"
    })
  
  if(os()== "Windows"){shell('taskkill.exe /F /IM openvpn.exe') } else {  
    
    proc_openvpn <- ifelse(os() == "Linux", "openvpn", "openvpn")
    
    a <- suppressWarnings(
      bashR::sudo(glue::glue("killall { proc_openvpn }"),
                  ignore.stderr = quiet,
                  ignore.stdout = quiet,
                  intern = quiet)
      
    )
  }
  while(time_out != 0){
    Sys.sleep(1)
    time_out <- time_out - 1
  }
}

#
# openvpn_config <- function(config_path, intern = T, time_out = 30){
#   openvpn_disconnect(2)
#
#   if(!fs::file_exists(config_path)){
#     stop("No config file, please check that you specified the right path to the config file")
#   }
#
#   current_ip <- get_current_ip()
#   message(glue("Current IP: { current_ip }"))
#
#   system(paste0("sudo /usr/local/sbin/openvpn --config ", config_path),
#          ignore.stdout = F, ignore.stderr = F, intern = intern, wait = F)
#
#   run_as_long_as(
#     expr = {cat(".") ; Sys.sleep(1)},
#     output_cond = current_ip != get_current_ip(),
#     max_iter = time_out
#   )
#
#   if(current_ip == get_current_ip()){
#     openvpn_disconnect()
#     cat("\n")
#     message("Connection could not be established")
#   } else {
#     message(glue("Connection Successfull\n New IP: { new_ip }"))
#   }
# }


#' #' generate_config_file
#' #' @export
#'
#' generate_config_file <- function(configurations, config_path = NULL){
#'   if(is.null(config_path)){
#'     stop("Please specify a path for configuration file, that you want to create.\nYou will then be able to connect to this VPN Tunnel, using this config path.")
#'   }
#'   write_lines(configurations, config_path)
#'
#'   message(glue("A config file has been created.
#'                You can now connect to your vpn tunnel using
#'                'openvpn_config({ config_path })'"))
#' }
