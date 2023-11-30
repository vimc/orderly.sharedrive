test_that("push", {
  paths <- setup_orderly(add_remote = FALSE)

  remote_path <- tempfile()
  cl <- orderly_remote_sharedrive(remote_path)

  expect_equal(cl$list_reports(), character(0))

  expect_error(cl$push("/not/a/path"), "Can't push report at path")

  res <- cl$push(paths$report_paths$example[1])

  expect_equal(cl$list_reports(), "example")
  expect_length(cl$list_versions("example"), 1)

  example <- file.path(remote_path, "archive", "example")
  expect_true(dir.exists(example))
  expect_true(file.exists(file.path(
    example, basename(paths$report_paths$example[1]))))

  res <- cl$push(paths$report_paths$example[2])
  expect_equal(cl$list_reports(), "example")
  expect_length(cl$list_versions("example"), 2)
  expect_true(file.exists(file.path(
    remote_path, "archive", "example",
    basename(paths$report_paths$example[2]))))

  res <- cl$push(paths$report_paths$example2[1])

  expect_equal(cl$list_reports(), c("example", "example2"))
  expect_length(cl$list_versions("example2"), 1)

  example2 <- file.path(remote_path, "archive", "example2")
  expect_true(dir.exists(example2))
  expect_true(file.exists(file.path(example2,
    basename(paths$report_paths$example2[1]))))
})

test_that("list_reports", {
  paths <- setup_orderly()

  cl <- orderly_remote_sharedrive(paths$remote)
  expect_equal(cl$list_reports(), c("example", "example2"))
})


test_that("list_versions", {
  paths <- setup_orderly()

  cl <- orderly_remote_sharedrive(paths$remote)
  expect_length(cl$list_versions("example"), 2)

  expect_equal(cl$list_versions("unknown"), character(0))
})


test_that("pull", {
  paths <- setup_orderly()
  cl <- orderly_remote_sharedrive(paths$remote)

  res <- cl$pull("example", basename(paths$report_paths$example[1]))

  expect_true(file.exists(res))
  expect_true(file.info(res)$isdir)
  expect_setequal(dir(res), dir(paths$report_paths$example[1]))
  expect_setequal(openssl::md5(dir(res)),
                  openssl::md5(dir(paths$report_paths$example[1])))
})


test_that("useful error returned when trying to pull missing report", {
  cl <- orderly_remote_sharedrive(tempfile())
  expect_error(cl$pull("thing", "123"),
               "file doesn't exist.")
})


test_that("metadata", {
  paths <- setup_orderly()
  cl <- orderly_remote_sharedrive(paths$remote)

  res <- cl$metadata("example", basename(paths$report_paths$example[1]))

  expect_true(file.exists(res))
  ## metadata can be read
  rds <- readRDS(res)
  expect_true(!is.null(rds))
})


test_that("useful error returned when trying to fetch metadata for unknown", {
  cl <- orderly_remote_sharedrive(tempfile())
  expect_error(cl$metadata("thing", "123"),
               "file doesn't exist.")
})


test_that("report_run is not supported", {
  cl <- orderly_remote_sharedrive(NULL)
  expect_error(cl$run(),
               "'orderly_remote_sharedrive' remotes do not run")
})


test_that("report_run is not supported", {
  cl <- orderly_remote_sharedrive(NULL)
  expect_error(cl$kill("my_key"),
               "'orderly_remote_sharedrive' remotes do not support kill")
})


test_that("url_report is not supported", {
  cl <- orderly_remote_sharedrive(NULL)
  expect_error(cl$url_report("a", "b"),
               "'orderly_remote_sharedrive' remotes do not support urls")
})

test_that("bundles are not supported", {
  cl <- orderly_remote_sharedrive(NULL)
  expect_error(cl$bundle_pack(),
               "'orderly_remote_sharedrive' remotes do not support bundles")
  expect_error(cl$bundle_import(),
               "'orderly_remote_sharedrive' remotes do not support bundles")
})
