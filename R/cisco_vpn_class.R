
cisco_tunnel <- R6::R6Class("cisco_vpn",
                            inherit = "vpn",
                            private = list(

                            ),
                            public = list(
                              initialize = function(){
                                self$id <- rstudioapi::showPrompt("Cisco VPN", "Please provide the host address")
                                self$type <- "cisco"
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
                                                         password = private$password)
                                successful_connection(success)
                              }
                            )
)


#' cisco_connect
#' @export

cisco_connect <- function(host, username, password){
  #print(host)
  current_ip <- get_current_ip()
  message(glue("Current IP: { current_ip }"))

  system(
    glue(
      "printf '{ username }\n{ password }\ny' | /opt/cisco/anyconnect/bin/vpn -s connect { host }"
    ), intern = F, ignore.stdout = F, ignore.stderr = F
  )

  run_as_long_as(
    expr = {cat(".") ; Sys.sleep(1) ; return(".")},
    output_cond = connect_env$current_ip != get_current_ip(),
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

  as.list(global_env()) %>%
    keep(~"vpn" %in% class(.x)) %>%
    map(~{
      .x$status <- "disconnected"
      .x$ip <- "disconnected"
    })

  if(force){
    system("sudo killall /opt/cisco/anyconnect/bin/vpn")
  } else {
    system("/opt/cisco/anyconnect/bin/vpn disconnect")
  }
}
