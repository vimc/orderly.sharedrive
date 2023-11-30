`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}


with_dir <- function(path, expr) {
  owd <- setwd(path)
  on.exit(setwd(owd))
  force(expr)
}


zip_dir <- function(path, dest = paste0(basename(path), ".zip")) {
  with_dir(dirname(path), {
    zip::zipr(dest, basename(path))
    normalizePath(dest)
  })
}
