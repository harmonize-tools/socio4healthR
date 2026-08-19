# R/harmonizer.R
# R Wrappers for socio4health.Harmonizer

#' Create a socio4health `Harmonizer` Object
#'
#' Direct wrapper for the `Harmonizer.__init__` constructor in Python.
#' All parameters are passed directly to the constructor.
#'
#' @param min_common_columns Minimum number of common columns for vertical merge.
#' @param nan_threshold NaN threshold for removing columns between 0 and 1.
#' @param sample_frac Sampling fraction for NaN.
#' @param column_mapping Enum, dict, JSON, or path to JSON.
#' @param value_mappings Enum, dict, JSON, or path to JSON.
#' @param theme_info Dict/JSON/path with theme/category information.
#' @param default_country Default country.
#' @param strict_mapping \code{TRUE} to require complete mappings.
#' @param dict_df R data frame or pandas DataFrame with the dictionary.
#' @param categories Vector of categories.
#' @param key_col Key column for row selection.
#' @param key_val Key values.
#' @param extra_cols Extra columns to preserve.
#' @param join_key Key column for joins.
#' @param aux_key Auxiliary key for joins.
#'
#' @return Python `Harmonizer` object.
#' @export
s4h_harmonizer <- function(min_common_columns = 1,
                           nan_threshold = 1.0,
                           sample_frac = NULL,
                           column_mapping = NULL,
                           value_mappings = NULL,
                           theme_info = NULL,
                           default_country = NULL,
                           strict_mapping = FALSE,
                           dict_df = NULL,
                           categories = NULL,
                           key_col = NULL,
                           key_val = NULL,
                           extra_cols = NULL,
                           join_key = NULL,
                           aux_key = NULL) {
  if (!is.numeric(min_common_columns) || length(min_common_columns) != 1L ||
      is.na(min_common_columns) || !is.finite(min_common_columns) ||
      min_common_columns < 1 || min_common_columns != floor(min_common_columns)) {
    stop("`min_common_columns` must be a positive whole number.", call. = FALSE)
  }
  if (!is.numeric(nan_threshold) || length(nan_threshold) != 1L ||
      is.na(nan_threshold) || nan_threshold < 0 || nan_threshold > 1) {
    stop("`nan_threshold` must be a number between 0 and 1.", call. = FALSE)
  }
  if (!is.null(sample_frac) &&
      (!is.numeric(sample_frac) || length(sample_frac) != 1L ||
       is.na(sample_frac) || sample_frac <= 0 || sample_frac > 1)) {
    stop("`sample_frac` must be NULL or a number greater than 0 and at most 1.", call. = FALSE)
  }

  mod <- .s4h_get_module()
  harmonizer_cls <- mod$Harmonizer

  harmonizer_cls(
    min_common_columns  = as.integer(min_common_columns),
    nan_threshold       = nan_threshold,
    sample_frac         = sample_frac,
    column_mapping      = column_mapping,
    value_mappings      = value_mappings,
    theme_info          = theme_info,
    default_country     = default_country,
    strict_mapping      = strict_mapping,
    dict_df             = dict_df,
    categories          = categories,
    key_col             = key_col,
    key_val             = key_val,
    extra_cols          = extra_cols,
    join_key            = join_key,
    aux_key             = aux_key
  )
}

#' Vertically Merge Dask DataFrames with `Harmonizer`
#'
#' Wrapper for `Harmonizer.s4h_vertical_merge()`.
#'
#' @param harmonizer Python `Harmonizer` object.
#' @param ddfs List of Dask DataFrames (typically output from \code{s4h_extract(..., "dask")}).
#' @param return_as \code{"dask"}, \code{"pandas"}, or \code{"data.frame"}.
#' @param overlap_threshold Numeric overlap coefficient between 0 and 1 required
#'   to group DataFrames.
#' @param method Merge strategy: \code{"union"} keeps every column and
#'   \code{"intersection"} keeps only common columns.
#'
#' @return List of DataFrames in the specified format.
#' @export
s4h_vertical_merge <- function(harmonizer,
                               ddfs,
                               return_as = c("dask", "pandas", "data.frame"),
                               overlap_threshold = 1.0,
                               method = c("union", "intersection")) {
  return_as <- match.arg(return_as)
  method <- match.arg(method)
  if (!is.numeric(overlap_threshold) || length(overlap_threshold) != 1L ||
      is.na(overlap_threshold) || overlap_threshold < 0 || overlap_threshold > 1) {
    stop("`overlap_threshold` must be a number between 0 and 1.", call. = FALSE)
  }

  res <- harmonizer$s4h_vertical_merge(
    ddfs,
    overlap_threshold = overlap_threshold,
    method = method
  )
  .s4h_convert_dataframe_list(res, return_as)
}

#' Drop Columns with Many NaN Values using `Harmonizer`
#'
#' Wrapper for `Harmonizer.drop_nan_columns()`.
#'
#' @param harmonizer Python `Harmonizer` object.
#' @param ddf_or_ddfs A Dask DataFrame or list of Dask DataFrames.
#' @param return_as \code{"dask"}, \code{"pandas"}, or \code{"data.frame"}.
#'
#' @return Object(s) in the specified format.
#' @export
s4h_drop_nan_columns <- function(harmonizer,
                                 ddf_or_ddfs,
                                 return_as = c("dask", "pandas", "data.frame")) {
  return_as <- match.arg(return_as)

  res <- harmonizer$drop_nan_columns(ddf_or_ddfs)

  if (inherits(res, c("python.builtin.list", "python.builtin.tuple")) ||
      (is.list(res) && !is.data.frame(res) &&
       !inherits(res, "python.builtin.object"))) {
    .s4h_convert_dataframe_list(res, return_as)
  } else {
    .s4h_convert_dataframe(res, return_as)
  }
}

#' Get Available Columns (Static)
#'
#' Wrapper for `Harmonizer.s4h_get_available_columns()`.
#'
#' @param df_or_dfs Dask DataFrame, pandas DataFrame, or list of DataFrames.
#'
#' @return Vector of column names.
#' @export
s4h_get_available_columns <- function(df_or_dfs) {
  mod <- .s4h_get_module()
  harmonizer_cls <- mod$Harmonizer
  columns <- harmonizer_cls$s4h_get_available_columns(df_or_dfs)
  unlist(reticulate::py_to_r(columns), use.names = FALSE)
}

#' Harmonize DataFrames by Country with `Harmonizer`
#'
#' Wrapper for `Harmonizer.s4h_harmonize_dataframes()`.
#'
#' @param harmonizer Python `Harmonizer` object.
#' @param country_dfs Python dictionary or named list of lists of Dask DataFrames.
#' @param return_as \code{"dask"}, \code{"pandas"}, or \code{"data.frame"}.
#'
#' @return Equivalent structure (dictionary/named list) with harmonized DataFrames.
#' @export
s4h_harmonize_dataframes <- function(harmonizer,
                                     country_dfs,
                                     return_as = c("dask", "pandas", "data.frame")) {
  return_as <- match.arg(return_as)

  if (!inherits(country_dfs, "python.builtin.dict")) {
    if (!is.list(country_dfs) || is.null(names(country_dfs)) ||
        any(!nzchar(names(country_dfs)))) {
      stop("`country_dfs` must be a named list or a Python dictionary.", call. = FALSE)
    }
    country_dfs <- reticulate::r_to_py(country_dfs, convert = FALSE)
  }

  res <- harmonizer$s4h_harmonize_dataframes(country_dfs)

  keys <- vapply(
    reticulate::iterate(res$keys(), simplify = FALSE),
    function(key) as.character(reticulate::py_to_r(key)),
    character(1)
  )
  out <- lapply(keys, function(k) {
    .s4h_convert_dataframe_list(res[[k]], return_as)
  })
  names(out) <- keys
  out
}

#' Compare Dask DataFrame Columns Against Dictionary
#'
#' Wrapper for `Harmonizer.s4h_compare_with_dict()`.
#'
#' @param harmonizer Python `Harmonizer` object with \code{dict_df} defined.
#' @param ddfs List of Dask DataFrames.
#' @param as_data_frame \code{TRUE} to return an R data.frame.
#'
#' @return pandas DataFrame (Python) or R data.frame.
#' @export
s4h_compare_with_dict <- function(harmonizer,
                                  ddfs,
                                  as_data_frame = TRUE) {
  res <- harmonizer$s4h_compare_with_dict(ddfs)
  if (as_data_frame) {
    reticulate::py_to_r(res)
  } else {
    res
  }
}

#' Select Rows/Columns with `Harmonizer.s4h_data_selector()`
#'
#' @param harmonizer Python `Harmonizer` object (must have \code{dict_df}, \code{categories},
#'   \code{key_col}, \code{key_val}, etc. configured).
#' @param ddfs List of Dask DataFrames.
#' @param return_as \code{"dask"}, \code{"pandas"}, or \code{"data.frame"}.
#'
#' @return List of filtered DataFrames.
#' @export
s4h_data_selector <- function(harmonizer,
                              ddfs,
                              return_as = c("dask", "pandas", "data.frame")) {
  return_as <- match.arg(return_as)
  res <- harmonizer$s4h_data_selector(ddfs)
  .s4h_convert_dataframe_list(res, return_as)
}

#' Join Multiple Dask DataFrames with `Harmonizer.s4h_join_data()`
#'
#' @param harmonizer Python `Harmonizer` object (with \code{join_key} and, optionally, \code{aux_key}).
#' @param ddfs List of Dask DataFrames.
#' @param as_data_frame \code{TRUE} to return R data.frame.
#'
#' @return pandas DataFrame or R data.frame.
#' @export
s4h_join_data <- function(harmonizer,
                          ddfs,
                          as_data_frame = TRUE) {
  res <- harmonizer$s4h_join_data(ddfs)  # pandas DataFrame
  if (as_data_frame) {
    reticulate::py_to_r(res)
  } else {
    res
  }
}

#' Call an Arbitrary Method on a `Harmonizer` Object
#'
#' @param harmonizer Python `Harmonizer` object.
#' @param method Name of the method in Python.
#' @param ... Additional arguments.
#'
#' @return The return value of the Python method.
#' @export
s4h_harmonizer_call <- function(harmonizer, method, ...) {
  fun <- harmonizer[[method]]
  if (is.null(fun)) {
    stop("The method '", method, "' does not exist in the Harmonizer object.")
  }
  fun(...)
}
