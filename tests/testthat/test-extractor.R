test_that("s4h_get_default_data_dir calls Python helper", {
  fake_module <- list(s4h_get_default_data_dir = function() "py-path")

  with_mocked_bindings(
    .s4h_get_module = function(module) fake_module,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        py_str = function(x) "/tmp/data",
        .package = "reticulate",
        {
          expect_equal(s4h_get_default_data_dir(), "/tmp/data")
        }
      )
    }
  )
})

test_that("s4h_extractor validates and passes current Python arguments", {
  fake_module <- list(Extractor = function(...) list(args = list(...)))

  with_mocked_bindings(
    .s4h_get_module = function() fake_module,
    .package = "socio4healthR",
    {
      result <- s4h_extractor(
        input_path = "x",
        depth = 2,
        down_ext = ".csv",
        encoding = "utf8",
        delete_zip_after = TRUE
      )
      expect_equal(result$args$input_path, "x")
      expect_equal(result$args$depth, 2)
      expect_equal(result$args$down_ext, ".csv")
      expect_equal(result$args$encoding, "utf8")
      expect_true(result$args$delete_zip_after)

      expect_error(s4h_extractor(character()), "input_path")
      expect_error(s4h_extractor("x", delete_zip_after = NA), "delete_zip_after")
    }
  )
})

test_that("s4h_extract returns dask, pandas, or data.frame", {
  ddf1 <- list(compute = function() "pd1")
  ddf2 <- list(compute = function() "pd2")
  extractor <- list(s4h_extract = function() list(ddf1, ddf2))

  with_mocked_bindings(
    py_has_attr = function(x, name) identical(name, "compute"),
    py_to_r = function(x) paste0("r-", x),
    .package = "reticulate",
    {
      expect_equal(s4h_extract(extractor, "dask"), list(ddf1, ddf2))
      expect_equal(s4h_extract(extractor, "pandas"), list("pd1", "pd2"))
      expect_equal(s4h_extract(extractor, "data.frame"), list("r-pd1", "r-pd2"))
    }
  )
})

test_that("s4h_delete_download_folder forwards and converts its result", {
  extractor <- list(
    s4h_delete_download_folder = function(folder_path = NULL) {
      if (is.null(folder_path)) TRUE else folder_path
    }
  )

  expect_true(s4h_delete_download_folder(extractor))
  expect_equal(s4h_delete_download_folder(extractor, "c:/tmp"), "c:/tmp")
})
