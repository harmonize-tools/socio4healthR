test_that("1.0.9 text wrappers preserve Python translation and classification behavior", {
  skip_if(
    Sys.getenv("SOCIO4HEALTH_RUN_INTEGRATION_TESTS") != "true",
    "Python integration tests are opt-in"
  )

  utils <- .s4h_get_module("socio4health.utils.harmonizer_utils")
  skip_if_not(reticulate::py_has_attr(utils, "_translate_texts"), "Requires socio4health 1.0.9")
  reticulate::py_run_string(paste(
    "import socio4health.utils.harmonizer_utils as _s4h_utils",
    "_s4h_original_translate = _s4h_utils._translate_texts",
    "_s4h_original_cache = _s4h_utils._translation_cache",
    "_s4h_original_classifier = _s4h_utils.s4h_get_classifier",
    "_s4h_batches = []",
    "def _s4h_test_translate(texts):",
    "    _s4h_batches.append(list(texts))",
    "    return ['translated:' + text for text in texts]",
    "def _s4h_test_classifier(text, **kwargs):",
    "    return [{'label': 'test-category'}]",
    "_s4h_utils._translate_texts = _s4h_test_translate",
    "_s4h_utils._translation_cache = {}",
    "_s4h_utils.s4h_get_classifier = lambda path: _s4h_test_classifier",
    sep = "\n"
  ))

  tryCatch({
    data <- data.frame(text = c("hola", "hola", NA_character_, "", "  "))
    result <- s4h_translate_column(data, "text")
    expect_named(result, c("text", "text_en"))
    expect_equal(result$text, data$text)
    expect_equal(result$text_en, c("translated:hola", "translated:hola", NA_character_, "", "  "))
    expect_false("text_en" %in% names(data))
    expect_equal(s4h_translate_column(data, "text")$text_en, result$text_en)
    expect_equal(reticulate::py_eval("_s4h_batches"), list("hola"))

    classified <- s4h_classify_rows(data, "text")
    expect_equal(classified$category, c("test-category", "test-category", "", "", ""))
    data$other <- c("", "", "texto", "not applicable", "")
    expect_equal(
      s4h_classify_rows(data, "text", "other")$category,
      c("test-category", "test-category", "test-category", "", "")
    )
    extractor <- s4h_extractor(tempdir(), output_path = tempdir(), on_bad_lines = "skip")
    expect_equal(reticulate::py_to_r(extractor$on_bad_lines), "skip")
  }, finally = {
    reticulate::py_run_string(paste(
      "_s4h_utils._translate_texts = _s4h_original_translate",
      "_s4h_utils._translation_cache = _s4h_original_cache",
      "_s4h_utils.s4h_get_classifier = _s4h_original_classifier",
      sep = "\n"
    ))
  })
})

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
