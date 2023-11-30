context("tools")

test_that("unpack archive", {
  testthat::skip_on_cran()
  path <- orderly1::orderly_example("minimal")
  id <- orderly1::orderly_run("example", root = path, echo = FALSE)
  p <- orderly1::orderly_commit(id, root = path)

  zip <- zip_dir(p)

  path <- unzip_archive(zip, "example", id)
  expect_equal(basename(path), id)
  expect_equal(sort(dir(file.path(path), recursive = TRUE)),
               sort(dir(p, recursive = TRUE)))
})


test_that("unpack report failure: corrupt download", {
  testthat::skip_on_cran()
  bytes <- as.raw(c(0x50, 0x4b, 0x05, 0x06, rep(0x00, 18L)))
  zip <- tempfile()
  writeBin(bytes, zip)
  ## This test might be platform dependent as a sane unzip function
  ## would have caught this.
  expect_error(suppressWarnings(
    unzip_archive(zip, NULL, NULL)),
    "Corrupt zip file? No files extracted",
    fixed = TRUE)
})


test_that("unpack failure: not an orderly archive", {
  testthat::skip_on_cran()
  tmp <- file.path(tempfile(), "parent")
  dir.create(tmp, FALSE, TRUE)
  file.create(file.path(tmp, c("a", "b")))
  zip <- tempfile(fileext = ".zip")
  with_dir(tmp, zip(zip, dir(), extras = "-q"))
  expect_error(unzip_archive(zip, NULL, NULL),
               "Invalid orderly archive")
})


test_that("unpack failure: not expected id", {
  testthat::skip_on_cran()
  id <- orderly1:::new_report_id()
  tmp <- file.path(tempfile(), id)
  dir.create(tmp, FALSE, TRUE)
  dir.create(file.path(tmp, "orderly.yml"))
  zip <- zip_dir(tmp)
  expect_error(unzip_archive(zip, NULL, "other"),
               sprintf("This is archive '%s' but expected 'other'", id),
               fixed = TRUE)
})


test_that("unpack failure: missing files", {
  testthat::skip_on_cran()
  id <- orderly1:::new_report_id()
  tmp <- file.path(tempfile(), id)
  dir.create(tmp, FALSE, TRUE)
  dir.create(file.path(tmp, "orderly.yml"))
  zip <- zip_dir(tmp)
  expect_error(unzip_archive(zip, NULL, id),
               "Invalid orderly archive: missing files orderly_run.rds",
               fixed = TRUE)
})
