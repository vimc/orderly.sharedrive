##' Implements an orderly "remote" using Sharepoint as a backend.  Use
##' this within an \code{orderly_config.yml} configuration.
##'
##' A configuration might look like:
##'
##' \preformatted{
##' remote:
##'   real:
##'     driver: orderly.sharepoint::orderly_remote_sharepoint
##'     args:
##'       url: https://example.sharepoint.com
##'       site: mysite
##'       path: Shared Documents/orderly/real
##' }
##'
##' which would create a remote called \code{real}, using your group's
##' Sharepoint hosted at \code{https://example.sharepoint.com}, on
##' site \code{mysite} and within that site using path \code{Shared
##' Documents/orderly/real}.
##'
##' Currently authentication is interactive, or uses the values of
##' environment variables \code{SHAREPOINT_USERNAME} and
##' \code{SHAREPOINT_PASS}.  Once we expose richer authentication
##' approaches in spud that will be exposed here (RESIDE-162).
##'
##' This function is not intended to be used interactively
##'
##' @title Create an orderly remote based on Sharepoint
##'
##' @param url Sharepoint URL
##'
##' @param site Sharepoint "site"
##'
##' @param path Path within the Sharepoint site. In our experience
##'   these often start with \code{Shared Documents} but your setup
##'   may vary.
##'
##' @param name Friendly name for the remote
##'
##' @return An \code{orderly_remote_sharepoint} object
##' @return An \code{orderly_remote_sharepoint} object, designed to be
##'   used by orderly.  This function should however not generally be
##'   called by users directly, as it should be used within
##'   \code{orderly_config.yml}
##' @export
orderly_remote_sharepoint <- function(url, site, path, name = NULL) {
  client <- orderly_sharepoint_client(url)
  folder <- orderly_sharepoint_folder(client, site, path)
  orderly_remote_sharepoint_$new(folder, name)
}


## Seems hard to mock the whole class out, which I think validates my
## general approach of exposing free constructor!
## https://github.com/r-lib/mockery/issues/21
orderly_sharepoint_client <- function(url) {
  spud::sharepoint$new(url) # nocov
}


orderly_sharepoint_folder <- function(client, site, path) {
  folder <- tryCatch(
    client$folder(site, path, verify = TRUE),
    error = function(e)
      stop(sprintf("Error reading from %s:%s - %s",
                   site, path, e$message), call. = FALSE))
  path <- "orderly.sharepoint"
  exists <- tryCatch({
    folder$download(path)
    TRUE
  }, error = function(e) FALSE)
  if (exists) {
    return(folder)
  }
  if (nrow(folder$list()) > 0L) {
    stop(sprintf(
      "Directory %s:%s cannot be used for orderly; contains other files",
      site, path))
  }
  tmp <- tempfile()
  on.exit(unlink(tmp))
  writeLines("orderly.sharepoint", tmp)
  folder$upload(tmp, path)
  folder$create("archive")
  folder
}


orderly_remote_sharepoint_ <- R6::R6Class(
  "orderly_remote_sharepoint",
  cloneable = FALSE,

  public = list(
    folder = NULL,
    name = NULL,

    initialize = function(folder, name = NULL) {
      self$folder <- folder
      self$name <- name
    },

    list_reports = function() {
      sort(self$folder$folders("archive")$name)
    },

    list_versions = function(name) {
      sort(self$folder$files(file.path("archive", name))$name)
    },

    push = function(path) {
      path_meta <- file.path(path, "orderly_run.rds")
      stopifnot(file.exists(path_meta))

      zip <- tempfile(fileext = ".zip")
      zip_dir(path, zip)
      on.exit(unlink(zip))

      dat <- readRDS(path_meta)
      name <- dat$meta$name
      id <- dat$meta$id

      self$folder$create(file.path("archive", name))
      self$folder$upload(zip, file.path("archive", name, id))
    },

    pull = function(name, id) {
      zip <- tempfile(fileext = ".zip")
      on.exit(unlink(zip))
      zip <- self$folder$download(file.path("archive", name, id), zip)
      unzip_archive(zip, name, id)
    },

    metadata = function(name, id) {
      archive_path <- self$pull(name, id)
      file.path(archive_path, "orderly_run.rds")
    },

    run = function(...) {
      stop("'orderly_remote_sharepoint' remotes do not run")
    },

    kill = function(...) {
      stop("'orderly_remote_sharepoint' remotes do not support kill")
    },

    url_report = function(name, id) {
      stop("'orderly_remote_sharepoint' remotes do not support urls")
    },

    bundle_pack = function(...) {
      stop("'orderly_remote_sharepoint' remotes do not support bundles")
    },

    bundle_import = function(...) {
      stop("'orderly_remote_sharepoint' remotes do not support bundles")
    }
  ))
