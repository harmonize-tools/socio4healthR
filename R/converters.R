.s4h_as_list <- function(x) {
  if (inherits(x, c("python.builtin.list", "python.builtin.tuple"))) {
    return(reticulate::iterate(x, simplify = FALSE))
  }

  if (is.list(x) && !is.data.frame(x)) {
    return(x)
  }

  stop("Expected a Python or R list of DataFrames.", call. = FALSE)
}

.s4h_convert_dataframe <- function(df, return_as) {
  if (return_as == "dask") {
    return(df)
  }

  is_python <- inherits(df, "python.builtin.object")
  if (is_python && reticulate::py_has_attr(df, "compute")) {
    df <- df$compute()
  } else if (!is_python &&
             (is.list(df) || is.environment(df)) &&
             is.function(df[["compute"]])) {
    df <- df[["compute"]]()
  }

  if (return_as == "pandas") {
    return(df)
  }

  reticulate::py_to_r(df)
}

.s4h_convert_dataframe_list <- function(dfs, return_as) {
  lapply(.s4h_as_list(dfs), .s4h_convert_dataframe, return_as = return_as)
}
