## NOTE: duplicated out of orderlyweb for now - it's not clear where
## this really belongs.  See VIMC-3771
unzip_archive <- function(zip, name, id) {
  dest <- tempfile()
  res <- utils::unzip(zip, exdir = dest)

  files <- dir(dest, all.files = TRUE, no.. = TRUE)
  if (length(files) == 0L) {
    stop("Corrupt zip file? No files extracted")
  } else if (length(files) > 1L) {
    stop("Invalid orderly archive", call. = FALSE)
  }
  if (files != id) {
    stop(sprintf("This is archive '%s' but expected '%s'",
                 files, id), call. = FALSE)
  }

  expected <- c("orderly.yml", "orderly_run.rds")
  msg <- !file.exists(file.path(dest, id, expected))
  if (any(msg)) {
    stop(sprintf("Invalid orderly archive: missing files %s",
                 paste(expected[msg], collapse = ", ")), call. = FALSE)
  }

  file.path(dest, id)
}
