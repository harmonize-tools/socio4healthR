.s4h_data_info_enums <- c(
  "CountryEnum",
  "NameEnum",
  "BraColnamesEnum",
  "BraColspecsEnum"
)

#' Access socio4health Data Information Enums
#'
#' Lists or retrieves values from the public enums in
#' `socio4health.enums.data_info_enum` without requiring callers to import the
#' Python module directly.
#'
#' @param enum Name of the enum class. If `NULL`, returns the supported enum
#'   class names.
#' @param member Name of an enum member. If `NULL`, returns the available
#'   members of `enum`.
#'
#' @return A character vector of enum or member names when `enum` or `member`
#'   is `NULL`. Otherwise, the selected enum value converted to R.
#'
#' @examples
#' s4h_get_data_info_enum()
#' \dontrun{
#' s4h_get_data_info_enum("CountryEnum")
#' s4h_get_data_info_enum("CountryEnum", "COLOMBIA")
#' s4h_get_data_info_enum("BraColnamesEnum", "PNADC")
#' s4h_get_data_info_enum("BraColspecsEnum", "PNADC")
#' }
#'
#' @export
s4h_get_data_info_enum <- function(enum = NULL, member = NULL) {
  if (is.null(enum)) {
    if (!is.null(member)) {
      stop("`member` cannot be supplied when `enum` is NULL.", call. = FALSE)
    }
    return(.s4h_data_info_enums)
  }

  if (!is.character(enum) || length(enum) != 1L || is.na(enum) ||
      !enum %in% .s4h_data_info_enums) {
    stop(
      "`enum` must be one of: ",
      paste(.s4h_data_info_enums, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!is.null(member) &&
      (!is.character(member) || length(member) != 1L || is.na(member) ||
       !nzchar(member))) {
    stop("`member` must be NULL or a single non-empty string.", call. = FALSE)
  }

  module <- .s4h_get_module("socio4health.enums.data_info_enum")
  enum_class <- module[[enum]]
  member_keys <- enum_class[["__members__"]]$keys()
  members <- vapply(
    reticulate::iterate(member_keys, simplify = FALSE),
    function(key) as.character(reticulate::py_to_r(key)),
    character(1L)
  )

  if (is.null(member)) {
    return(members)
  }

  member_index <- match(toupper(member), toupper(members))
  if (is.na(member_index)) {
    stop(
      "Unknown member `", member, "` for `", enum, "`. Available members: ",
      paste(members, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  reticulate::py_to_r(enum_class[[members[[member_index]]]]$value)
}
