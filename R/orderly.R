##' Implements an orderly "remote" using a shared drive as a backend.  Use
##' this within an \code{orderly_config.yml} configuration.
##'
##' A configuration might look like:
##'
##' \preformatted{
##' remote:
##'   real:
##'     driver: orderly.sharedrive::orderly_remote_sharedrive
##'     args:
##'       path: ~/path/to/network/drive
##' }
##'
##' which would create a remote called \code{real}, at the file path
##' specified. This can be a network drive or a one drive synced drive.
##'
##' This function is not intended to be used interactively
##'
##' @title Create an orderly remote based at a path
##'
##' @param path Path to use as a remote
##'
##' @param name Friendly name for the remote
##'
##' @return An \code{orderly_remote_sharedrive} object
##' @return An \code{orderly_remote_sharedrive} object, designed to be
##'   used by orderly.  This function should however not generally be
##'   called by users directly, as it should be used within
##'   \code{orderly_config.yml}
##' @export
orderly_remote_sharedrive <- function(path, name = NULL) {
  orderly_remote_sharedrive_$new(path, name)
}


orderly_remote_sharedrive_ <- R6::R6Class(
  "orderly_remote_sharedrive",
  cloneable = FALSE,

  public = list(
    path = NULL,
    archive_root = NULL,
    name = NULL,

    initialize = function(path, name = NULL) {
      self$path <- path
      self$archive_root <- file.path(path, "archive")
      self$name <- name
    },

    list_reports = function() {
      basename(list.dirs(self$archive_root, recursive = FALSE))
    },

    list_versions = function(name) {
      sort(list.files(file.path(self$archive_root, name)))
    },

    push = function(path) {
      path_meta <- file.path(path, "orderly_run.rds")
      if (!file.exists(path_meta)) {
        cli::cli_abort("Can't push report at path '{path_meta}', report doesn't exist.")
      }

      dat <- readRDS(path_meta)
      name <- dat$meta$name
      id <- dat$meta$id

      dir.create(file.path(self$archive_root, name), FALSE, TRUE)
      zip_dir(path, file.path(self$archive_root, name, id))
    },

    pull = function(name, id) {
      unzip_archive(file.path(self$archive_root, name, id), name, id)
    },

    metadata = function(name, id) {
      archive_path <- self$pull(name, id)
      file.path(archive_path, "orderly_run.rds")
    },

    run = function(...) {
      stop("'orderly_remote_sharedrive' remotes do not run")
    },

    kill = function(...) {
      stop("'orderly_remote_sharedrive' remotes do not support kill")
    },

    url_report = function(name, id) {
      stop("'orderly_remote_sharedrive' remotes do not support urls")
    },

    bundle_pack = function(...) {
      stop("'orderly_remote_sharedrive' remotes do not support bundles")
    },

    bundle_import = function(...) {
      stop("'orderly_remote_sharedrive' remotes do not support bundles")
    }
  ))
