test_that("wrappers preserve Dask, pandas, and R return types", {
  skip_if(
    Sys.getenv("SOCIO4HEALTH_RUN_INTEGRATION_TESTS") != "true",
    "Python integration tests are opt-in"
  )

  pd <- reticulate::import("pandas", convert = FALSE)
  dd <- reticulate::import("dask.dataframe", convert = FALSE)
  dataframe <- dd$from_pandas(
    pd$DataFrame(reticulate::dict(x = c(1L, 2L), y = c(3L, 4L))),
    npartitions = 1L
  )
  harmonizer <- s4h_harmonizer()

  pandas_result <- s4h_vertical_merge(
    harmonizer,
    list(dataframe),
    return_as = "pandas"
  )
  expect_s3_class(pandas_result[[1]], "pandas.core.frame.DataFrame")

  r_result <- s4h_vertical_merge(
    harmonizer,
    list(dataframe),
    return_as = "data.frame"
  )
  expect_s3_class(r_result[[1]], "data.frame")

  dropped <- s4h_drop_nan_columns(
    harmonizer,
    list(dataframe),
    return_as = "pandas"
  )
  expect_length(dropped, 1)
  expect_s3_class(dropped[[1]], "pandas.core.frame.DataFrame")

  harmonized <- s4h_harmonize_dataframes(
    harmonizer,
    list(CO = list(dataframe)),
    return_as = "data.frame"
  )
  expect_named(harmonized, "CO")
  expect_s3_class(harmonized$CO[[1]], "data.frame")

  expect_equal(
    s4h_get_data_info_enum("CountryEnum", "COLOMBIA"),
    "COL"
  )
  expect_length(
    s4h_get_data_info_enum("BraColnamesEnum", "PNADC"),
    420L
  )
  expect_length(
    s4h_get_data_info_enum("BraColspecsEnum", "PNADC"),
    420L
  )
})
