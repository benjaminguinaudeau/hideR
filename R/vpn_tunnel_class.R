#' vpn_tunnel
#' @export

vpn_tunnel <- R6::R6Class("vpn",
                          #inherit = keras_embed,
                          private = list(
                            username = NULL,
                            password = NULL,
                            init_time = NULL
                          ),
                          public = list(
                            id = NULL,
                            ip = NULL,
                            status = "disconnected",
                            initialize = function(){
                              if(fs::dir_exists(vpn_dir())) fs::dir_create(vpn_dir())
                            },
                            set_credentials = function(new_file, credential_path){

                              if(new_file){
                                private$username <- rstudioapi::showPrompt(
                                  title = "VPN Authentification",
                                  message = "Please provide your VPN Username"
                                )

                                private$password <- rstudioapi::askForPassword(
                                  prompt = "Please provide your VPN Password"
                                )
                              } else {
                                private$username <- read_lines(credential_path)[1]
                                private$password <- read_lines(credential_path)[2]

                              }

                            },
                            running_time = function(){
                              if(self$status == "disconnected"){
                                message("vpn not running")
                                return(NULL)
                              }

                              if(self$status == "connected"){
                                return(lubridate::make_difftime(Sys.time() - private$init_time))
                              }
                            }
                          )
)
