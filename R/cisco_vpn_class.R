#' cisco_tunnel
#' @export


cisco_tunnel <- R6::R6Class("cisco_vpn",
                            inherit = vpn_tunnel,
                            private = list(

                            ),
                            public = list(
                              initialize = function(){
                                self$id <- rstudioapi::showPrompt("Cisco VPN", "Please provide the host address")
                                self$set_credentials(T)
                              },
                              save = function(){
                                if(!dir.exists(paste0(vpn_dir(), "/cisco"))){
                                  dir.create(paste0(vpn_dir(), "/cisco"))
                                }


                                save_path <-  paste0(vpn_dir, "/",
                                                     self$id, ".Rdata")

                                save(self, file = save_path)
                              },
                              disconnect = function(force = F){
                                cisco_disconnect(force = force)
                              },
                              connect = function(prune_password = F,
                                                 time_out = 20,
                                                 quiet = T){
                                if(prune_password | is.null(private$username)){
                                  self$set_credentials(new_file = T)
                                }

                                success <- cisco_connect(host = self$id,
                                                         username = private$username,
                                                         password = private$password, 
                                                         time_out = time_out)
                                
                                if(success){
                                  self$status <- "connected"
                                  self$ip <- get_current_ip()
                                  private$init_time <- Sys.time()
                                }
                              }
                            )
)


#' cisco_connect
#' @export

cisco_connect <- function(host, username, password, time_out = 20){
  
  cisco_disconnect(force = F)
  
  connect_env <- current_env()
  #print(host)
  current_ip <- get_current_ip()
  message(glue("Current IP: { current_ip }"))
  
  cisco_cmd <- ifelse(os() == "Linux", "openconnect", "/opt/cisco/anyconnect/bin/vpn -s connect")
  
  if(os() == "Linux"){
    bashR::sudo(
      glue(
        "echo {password } | sudo { cisco_cmd } -u { username } vpn.uni-konstanz.de &"
      ), intern = F, ignore.stdout = F, ignore.stderr = F
    )
  } else {
    bashR::sudo(
      glue(
        "printf '{ username }\n{ password }\ny' | { cisco_cmd } { host } &"
      ), intern = F, ignore.stdout = F, ignore.stderr = F
    )
  }

  run_as_long_as(
    expr = {cat(".") ; Sys.sleep(1) ; return(".")},
    obj = list(current_ip = current_ip),
    output_cond = current_ip != get_current_ip(),
    max_iter = time_out
  )

  if(current_ip == get_current_ip()){
    openvpn_disconnect()
    cat("\n")
    message("Connexion could not be established")
    return(F)
  } else {
    message(glue("Connexion Successfull\n New IP: { get_current_ip() }"))
    return(T)
  }
}


#' cisco_disconnect
#' @export

cisco_disconnect <- function(force = F){

  cisco_cmd <- ifelse(os() == "Linux", "openconnect", "vpnagentd")
  
  as.list(global_env()) %>%
    keep(~"vpn" %in% class(.x)) %>%
    map(~{
      .x$status <- "disconnected"
      .x$ip <- "disconnected"
    })

  if(force){
    system(glue("sudo killall { cisco_cmd }"))
  } else {
    if(os() == "Linux"){
      system(glue("sudo killall { cisco_cmd }"))  
    } else {
      system("/opt/cisco/anyconnect/bin/vpn disconnect")
    }
  }
}
