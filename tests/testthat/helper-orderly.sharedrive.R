#' Set up orderly for tests
#'
#' This will create an orderly instance with 2 run reports
#'   * example which has been run twice
#'   * example2 which has also been run twice
#'
#' @param add_remote If true then will setup a sharedrive remote and push
#'   all reports to it.
#'
#' @return The path to the orderly instance
setup_orderly <- function(add_remote = TRUE) {
  path <- orderly1::orderly_example("minimal")
  example1_1 <- orderly1::orderly_run("example", root = path, echo = FALSE)
  p1 <- orderly1::orderly_commit(example1_1, root = path)
  example1_2 <- orderly1::orderly_run("example", root = path, echo = FALSE)
  p2 <- orderly1::orderly_commit(example1_2, root = path)
  example2_1 <- orderly1::orderly_run("example2", root = path, echo = FALSE)
  p3 <- orderly1::orderly_commit(example2_1, root = path)
  example2_2 <- orderly1::orderly_run("example2", root = path, echo = FALSE)
  p4 <- orderly1::orderly_commit(example2_2, root = path)

  remote_path <- NULL
  if (add_remote) {
    remote_path <- tempfile()

    cl <- orderly_remote_sharedrive(remote_path)
    res1 <- cl$push(p1)
    res2 <- cl$push(p2)
    res3 <- cl$push(p3)
    res4 <- cl$push(p4)
  }

  list(
    root = path,
    remote = remote_path,
    report_paths = list(example = c(p1, p2),
                        example2 = c(p3, p4))
  )
}
