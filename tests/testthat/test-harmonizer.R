python_ddf <- function(value) {
  result <- new.env(parent = emptyenv())
  result$compute <- function() value
  result
}

test_that("s4h_harmonizer validates and passes constructor arguments", {
  fake_module <- list(Harmonizer = function(...) list(args = list(...)))

  with_mocked_bindings(
    .s4h_get_module = function() fake_module,
    .package = "socio4healthR",
    {
      result <- s4h_harmonizer(
        min_common_columns = 2,
        nan_threshold = 0.5,
        sample_frac = 0.25
      )
      expect_equal(result$args$min_common_columns, 2L)
      expect_equal(result$args$nan_threshold, 0.5)
      expect_equal(result$args$sample_frac, 0.25)

      expect_error(s4h_harmonizer(min_common_columns = 2.7), "whole number")
      expect_error(s4h_harmonizer(nan_threshold = 2), "between 0 and 1")
      expect_error(s4h_harmonizer(sample_frac = 0), "sample_frac")
    }
  )
})

test_that("s4h_vertical_merge forwards arguments and converts output", {
  ddf1 <- python_ddf("pd1")
  ddf2 <- python_ddf("pd2")
  captured <- NULL
  harmonizer <- list(
    s4h_vertical_merge = function(ddfs, overlap_threshold, method) {
      captured <<- list(
        ddfs = ddfs,
        overlap_threshold = overlap_threshold,
        method = method
      )
      list(ddf1, ddf2)
    }
  )

  with_mocked_bindings(
    py_has_attr = function(x, name) identical(name, "compute"),
    py_to_r = function(x) paste0("r-", x),
    .package = "reticulate",
    {
      expect_equal(
        s4h_vertical_merge(
          harmonizer,
          list("a"),
          "dask",
          overlap_threshold = 0.5,
          method = "intersection"
        ),
        list(ddf1, ddf2)
      )
      expect_equal(captured$ddfs, list("a"))
      expect_equal(captured$overlap_threshold, 0.5)
      expect_equal(captured$method, "intersection")
      expect_equal(s4h_vertical_merge(harmonizer, list("a"), "pandas"), list("pd1", "pd2"))
      expect_equal(s4h_vertical_merge(harmonizer, list("a"), "data.frame"), list("r-pd1", "r-pd2"))
      expect_error(
        s4h_vertical_merge(harmonizer, list("a"), overlap_threshold = 2),
        "between 0 and 1"
      )
      expect_error(
        s4h_vertical_merge(harmonizer, list("a"), method = "invalid"),
        "arg"
      )
    }
  )
})

test_that("s4h_drop_nan_columns handles lists and single DataFrames", {
  ddf1 <- python_ddf("pd1")
  ddf2 <- python_ddf("pd2")
  harmonizer_list <- list(drop_nan_columns = function(x) list(ddf1, ddf2))
  harmonizer_one <- list(drop_nan_columns = function(x) ddf1)

  with_mocked_bindings(
    py_has_attr = function(x, name) identical(name, "compute"),
    py_to_r = function(x) paste0("r-", x),
    .package = "reticulate",
    {
      expect_equal(
        s4h_drop_nan_columns(harmonizer_list, list("a"), "data.frame"),
        list("r-pd1", "r-pd2")
      )
      expect_equal(
        s4h_drop_nan_columns(harmonizer_one, list("a"), "pandas"),
        "pd1"
      )
    }
  )
})

test_that("s4h_get_available_columns returns an R vector", {
  fake_module <- list(
    Harmonizer = list(
      s4h_get_available_columns = function(x) list("COL1", "COL2")
    )
  )

  with_mocked_bindings(
    .s4h_get_module = function() fake_module,
    .package = "socio4healthR",
    {
      expect_equal(s4h_get_available_columns("x"), c("COL1", "COL2"))
    }
  )
})

test_that("s4h_harmonize_dataframes handles converted Python dictionaries", {
  ddf1 <- python_ddf(data.frame(a = 1))
  ddf2 <- python_ddf(data.frame(a = 2))
  result <- list(
    keys = function() c("CO", "BR"),
    CO = list(ddf1),
    BR = list(ddf2)
  )
  harmonizer <- list(s4h_harmonize_dataframes = function(country_dfs) result)

  with_mocked_bindings(
    r_to_py = function(x, convert = FALSE) x,
    py_to_r = function(x) x,
    iterate = function(x, simplify = TRUE) as.list(x),
    py_has_attr = function(x, name) identical(name, "compute"),
    .package = "reticulate",
    {
      output <- s4h_harmonize_dataframes(
        harmonizer,
        list(CO = list("x")),
        "data.frame"
      )
      expect_equal(names(output), c("CO", "BR"))
      expect_true(is.data.frame(output[[1]][[1]]))
      expect_error(
        s4h_harmonize_dataframes(harmonizer, list(list("x"))),
        "named list"
      )
    }
  )
})

test_that("pandas-returning wrappers preserve or convert Python results", {
  harmonizer <- list(
    s4h_compare_with_dict = function(ddfs) "py_compare",
    s4h_join_data = function(ddfs) "py_join"
  )

  with_mocked_bindings(
    py_to_r = function(x) paste0("r-", x),
    .package = "reticulate",
    {
      expect_equal(s4h_compare_with_dict(harmonizer, list("a"), TRUE), "r-py_compare")
      expect_equal(s4h_compare_with_dict(harmonizer, list("a"), FALSE), "py_compare")
      expect_equal(s4h_join_data(harmonizer, list("a"), TRUE), "r-py_join")
      expect_equal(s4h_join_data(harmonizer, list("a"), FALSE), "py_join")
    }
  )
})

test_that("dataframe conversion helpers distinguish output formats", {
  ddf <- python_ddf("pd")

  with_mocked_bindings(
    py_has_attr = function(x, name) identical(name, "compute"),
    py_to_r = function(x) paste0("r-", x),
    .package = "reticulate",
    {
      expect_equal(.s4h_convert_dataframe_list(list(ddf), "dask"), list(ddf))
      expect_equal(.s4h_convert_dataframe_list(list(ddf), "pandas"), list("pd"))
      expect_equal(.s4h_convert_dataframe_list(list(ddf), "data.frame"), list("r-pd"))
    }
  )
})

test_that("s4h_data_selector delegates and converts", {
  ddf <- python_ddf("pd")
  harmonizer <- list(s4h_data_selector = function(ddfs) list(ddf))

  with_mocked_bindings(
    py_has_attr = function(x, name) identical(name, "compute"),
    py_to_r = function(x) paste0("r-", x),
    .package = "reticulate",
    {
      expect_equal(
        s4h_data_selector(harmonizer, list("a"), "data.frame"),
        list("r-pd")
      )
    }
  )
})

test_that("s4h_harmonizer_call invokes methods and reports missing ones", {
  harmonizer <- list(foo = function(x) x + 1)

  expect_equal(s4h_harmonizer_call(harmonizer, "foo", 1), 2)
  expect_error(s4h_harmonizer_call(harmonizer, "bar"), "does not exist")
})
