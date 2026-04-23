log_message <- function(message, level = "INFO") {
  line <- sprintf("[%s] [%s] %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), level, message)

  cat(line, "\n")
  write(line, file = here::here("output", "logs", "pipeline.log"), append = TRUE)
}
