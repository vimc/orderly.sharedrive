context("orderly")

test_that("list_reports calls folder$folders('archive')", {
  folder <- list(folders = mockery::mock(list(name = c("a", "b", "c"))))
  cl <- orderly_remote_sharepoint_$new(folder)
  expect_equal(cl$list_reports(), c("a", "b", "c"))
  mockery::expect_called(folder$folders, 1)
  expect_equal(mockery::mock_args(folder$folders)[[1]], list("archive"))
})


test_that("list_versions calls folder$files('archive/<name>')", {
  folder <- list(files = mockery::mock(list(name = c("a", "b", "c"))))
  cl <- orderly_remote_sharepoint_$new(folder)
  expect_equal(cl$list_versions("x"), c("a", "b", "c"))
  mockery::expect_called(folder$files, 1)
  expect_equal(mockery::mock_args(folder$files)[[1]], list("archive/x"))
})


test_that("pull", {
  path <- orderly1::orderly_example("minimal")
  id <- orderly1::orderly_run("example", root = path, echo = FALSE)
  p <- orderly1::orderly_commit(id, root = path)
  zip <- zip_dir(p)

  folder <- list(download = mockery::mock(zip))
  cl <- orderly_remote_sharepoint_$new(folder)
  res <- cl$pull("example", id)

  expect_true(file.exists(res))
  expect_true(file.info(res)$isdir)
  expect_setequal(dir(res), dir(p))

  mockery::expect_called(folder$download, 1)
  args <- mockery::mock_args(folder$download)[[1]]
  expect_equal(args[[1]], file.path("archive/example", id))
  expect_match(args[[2]], "\\.zip$")
  expect_equal(normalizePath(dirname(args[[2]]), mustWork = TRUE),
               normalizePath(tempdir(), mustWork = TRUE))
})

test_that("metadata", {
  path <- orderly1::orderly_example("minimal")
  id <- orderly1::orderly_run("example", root = path, echo = FALSE)
  p <- orderly1::orderly_commit(id, root = path)
  zip <- zip_dir(p)

  folder <- list(download = mockery::mock(zip))
  cl <- orderly_remote_sharepoint_$new(folder)
  res <- cl$metadata("example", id)

  expect_true(file.exists(res))
  ## metadata can be read
  rds <- readRDS(res)
  expect_true(!is.null(rds))

  mockery::expect_called(folder$download, 1)
  args <- mockery::mock_args(folder$download)[[1]]
  expect_equal(args[[1]], file.path("archive/example", id))
  expect_match(args[[2]], "\\.zip$")
  expect_equal(normalizePath(dirname(args[[2]]), mustWork = TRUE),
               normalizePath(tempdir(), mustWork = TRUE))
})


test_that("push", {
  path <- orderly1::orderly_example("minimal")
  id <- orderly1::orderly_run("example", root = path, echo = FALSE)
  p <- orderly1::orderly_commit(id, root = path)

  folder <- list(create = mockery::mock(), upload = mockery::mock())

  cl <- orderly_remote_sharepoint_$new(folder)

  mock_zip <- mockery::mock(NULL)
  mockery::stub(cl$push, "zip_dir", mock_zip)
  res <- cl$push(p)

  mockery::expect_called(mock_zip, 1)
  args <- mockery::mock_args(mock_zip)[[1]]
  expect_equal(args[[1]], p)
  expect_match(args[[2]], "\\.zip$")
  zip <- args[[2]]

  mockery::expect_called(folder$create, 1)
  expect_equal(
    mockery::mock_args(folder$create)[[1]],
    list("archive/example"))
  mockery::expect_called(folder$upload, 1)
  expect_equal(
    mockery::mock_args(folder$upload)[[1]],
    list(zip, file.path("archive/example", id)))
})


test_that("report_run is not supported", {
  cl <- orderly_remote_sharepoint_$new(NULL)
  expect_error(cl$run(),
               "'orderly_remote_sharepoint' remotes do not run")
})


test_that("report_run is not supported", {
  cl <- orderly_remote_sharepoint_$new(NULL)
  expect_error(cl$kill("my_key"),
               "'orderly_remote_sharepoint' remotes do not support kill")
})


test_that("url_report is not supported", {
  cl <- orderly_remote_sharepoint_$new(NULL)
  expect_error(cl$url_report("a", "b"),
               "'orderly_remote_sharepoint' remotes do not support urls")
})

test_that("bundles are not supported", {
  cl <- orderly_remote_sharepoint_$new(NULL)
  expect_error(cl$bundle_pack(),
               "'orderly_remote_sharepoint' remotes do not support bundles")
  expect_error(cl$bundle_import(),
               "'orderly_remote_sharepoint' remotes do not support bundles")
})


test_that("verify path on creation", {
  client <- list(
    folder = mockery::mock(stop("some error")))
  expect_error(
    orderly_sharepoint_folder(client, "site", "path"),
    "Error reading from site:path - some error")

  mockery::expect_called(client$folder, 1)
  expect_equal(mockery::mock_args(client$folder)[[1]],
               list("site", "path", verify = TRUE))
})


test_that("skip if already created", {
  folder <- list(download = mockery::mock("orderly.sharepoint"))
  client <- list(folder = mockery::mock(folder))

  res <- orderly_sharepoint_folder(client, "site", "path")
  expect_identical(res, folder)

  mockery::expect_called(client$folder, 1)
  expect_equal(mockery::mock_args(client$folder)[[1]],
               list("site", "path", verify = TRUE))

  mockery::expect_called(folder$download, 1)
  expect_equal(mockery::mock_args(folder$download)[[1]],
               list("orderly.sharepoint"))
})


test_that("continue if not created", {
  folder <- list(download = mockery::mock(stop("not found")),
                 list = mockery::mock(data.frame(name = character(0))),
                 create = mockery::mock(NULL),
                 upload = mockery::mock(NULL))
  client <- list(folder = mockery::mock(folder))

  res <- orderly_sharepoint_folder(client, "site", "path")
  expect_identical(res, folder)

  mockery::expect_called(client$folder, 1)
  expect_equal(mockery::mock_args(client$folder)[[1]],
               list("site", "path", verify = TRUE))

  mockery::expect_called(folder$download, 1)
  expect_equal(mockery::mock_args(folder$download)[[1]],
               list("orderly.sharepoint"))

  mockery::expect_called(folder$list, 1)
  expect_equal(mockery::mock_args(folder$list)[[1]], list())

  mockery::expect_called(folder$upload, 1)
  args <- mockery::mock_args(folder$upload)[[1]]
  expect_equal(args[[2]], "orderly.sharepoint")

  mockery::expect_called(folder$create, 1)
  expect_equal(mockery::mock_args(folder$create)[[1]],
               list("archive"))
})


test_that("error if files exist", {
  folder <- list(download = mockery::mock(stop("not found")),
                 list = mockery::mock(data.frame(name = "a")),
                 upload = mockery::mock(NULL))
  client <- list(folder = mockery::mock(folder))

  expect_error(
    orderly_sharepoint_folder(client, "site", "path"),
    paste("Directory site:orderly.sharepoint cannot be used for orderly;",
          "contains other files"))

  mockery::expect_called(client$folder, 1)
  expect_equal(mockery::mock_args(client$folder)[[1]],
               list("site", "path", verify = TRUE))

  mockery::expect_called(folder$download, 1)
  expect_equal(mockery::mock_args(folder$download)[[1]],
               list("orderly.sharepoint"))

  mockery::expect_called(folder$list, 1)
  expect_equal(mockery::mock_args(folder$list)[[1]], list())

  mockery::expect_called(folder$upload, 0)
})


test_that("creation", {
  folder <- new.env()
  mock_folder <- mockery::mock(folder)
  client <- new.env()
  mock_client <- mockery::mock(client)

  mockery::stub(orderly_remote_sharepoint, "orderly_sharepoint_client",
                mock_client)
  mockery::stub(orderly_remote_sharepoint, "orderly_sharepoint_folder",
                mock_folder)
  res <- orderly_remote_sharepoint("https://example.com", "site", "path",
                                   name = "name")
  expect_identical(res$folder, folder)
  expect_identical(res$name, "name")

  mockery::expect_called(mock_client, 1)
  expect_equal(mockery::mock_args(mock_client)[[1]],
               list("https://example.com"))

  mockery::expect_called(mock_folder, 1)
  expect_identical(mockery::mock_args(mock_folder)[[1]],
                   list(client, "site", "path"))
})
