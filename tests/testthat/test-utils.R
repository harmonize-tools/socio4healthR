test_that("s4h_standardize_dict validates required input and converts", {
  fake_module <- list(s4h_standardize_dict = function(x) "py_res")

  expect_error(s4h_standardize_dict(list(a = 1)), "data.frame")
  expect_error(
    s4h_standardize_dict(data.frame(question = "q")),
    "missing required columns"
  )

  with_mocked_bindings(
    .s4h_get_module = function(module) fake_module,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        r_to_py = function(x) x,
        py_to_r = function(x) "r_res",
        .package = "reticulate",
        {
          data <- data.frame(
            question = "q",
            variable_name = "v",
            description = "d",
            value = "1"
          )
          expect_equal(s4h_standardize_dict(data), "r_res")
        }
      )
    }
  )
})

test_that("s4h_translate_column validates column and converts", {
  fake_module <- list(s4h_translate_column = function(...) "py_res")
  data <- data.frame(text = "hola")

  expect_error(s4h_translate_column(list(a = 1), "a"), "data.frame")
  expect_error(s4h_translate_column(data, "missing"), "name a column")
  expect_error(s4h_translate_column(data, "text", NA_character_), "language")

  with_mocked_bindings(
    .s4h_get_module = function(module) fake_module,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        r_to_py = function(x) x,
        py_to_r = function(x) "r_res",
        .package = "reticulate",
        {
          expect_equal(s4h_translate_column(data, "text", "en"), "r_res")
        }
      )
    }
  )
})

test_that("s4h_get_classifier returns the Python object", {
  fake_module <- list(
    s4h_get_classifier = function(path) paste0("classifier:", path)
  )

  with_mocked_bindings(
    .s4h_get_module = function(module) fake_module,
    .package = "socio4healthR",
    {
      expect_equal(s4h_get_classifier("model"), "classifier:model")
    }
  )
})

test_that("s4h_classify_rows validates columns and converts", {
  fake_module <- list(s4h_classify_rows = function(...) "py_res")
  data <- data.frame(a = "x", b = "y", c = "z")

  expect_error(s4h_classify_rows(list(a = 1), "a", "b", "c"), "data.frame")
  expect_error(s4h_classify_rows(data, "a", "b", "missing"), "must name columns")

  with_mocked_bindings(
    .s4h_get_module = function(module) fake_module,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        r_to_py = function(x) x,
        py_to_r = function(x) "r_res",
        .package = "reticulate",
        {
          expect_equal(
            s4h_classify_rows(
              data,
              "a",
              "b",
              "c",
              new_column_name = "cat",
              MODEL_PATH = "m"
            ),
            "r_res"
          )
        }
      )
    }
  )
})

test_that("s4h_parse_fwf_dict validates positions and converts", {
  captured <- NULL
  fake_module <- list(
    s4h_parse_fwf_dict = function(dic) {
      captured <<- dic
      list(c("col1", "col2"), list(c(0, 1), c(1, 2)))
    }
  )

  expect_error(s4h_parse_fwf_dict(list(a = 1)), "data.frame")
  expect_error(
    s4h_parse_fwf_dict(data.frame(variable_name = "a")),
    "initial_position"
  )
  expect_error(
    s4h_parse_fwf_dict(data.frame(variable_name = "a", initial_position = 1)),
    "either `size` or `final_position`"
  )
  expect_error(
    s4h_parse_fwf_dict(data.frame(
      variable_name = "a",
      initial_position = "bad",
      size = 1
    )),
    "positive whole numbers"
  )

  with_mocked_bindings(
    .s4h_get_module = function(module) fake_module,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        r_to_py = function(x) x,
        py_to_r = function(x) x,
        .package = "reticulate",
        {
          dictionary <- data.frame(
            variable_name = "a",
            initial_position = factor("1"),
            size = factor("1")
          )
          result <- s4h_parse_fwf_dict(dictionary)
          expect_equal(result$colnames, c("col1", "col2"))
          expect_length(result$colspecs, 2)
          expect_equal(captured$initial_position, 1)
          expect_equal(captured$size, 1)
          expect_false("final_position" %in% names(captured))
        }
      )
    }
  )
})
