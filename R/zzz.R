.s4h_modules <- new.env(parent = emptyenv())

.s4h_prefer_managed_python <- function() {
  explicit_selection <- nzchar(Sys.getenv("RETICULATE_PYTHON")) ||
    nzchar(Sys.getenv("RETICULATE_PYTHON_ENV")) ||
    nzchar(Sys.getenv("RETICULATE_USE_MANAGED_VENV"))

  if (!explicit_selection) {
    Sys.setenv(RETICULATE_USE_MANAGED_VENV = "yes")
  }
}

.s4h_declare_python_requirements <- function() {
  reticulate::py_require(
    packages = c(
      "socio4health>=1.0.7,<2",
      "pandas>=2,<3",
      "torch==2.8.0; sys_platform == 'win32'",
      "torchvision==0.23.0; sys_platform == 'win32'",
      "torchaudio==2.8.0; sys_platform == 'win32'"
    ),
    python_version = ">=3.10,<4"
  )
}

.s4h_get_module <- function(module = "socio4health") {
  if (exists(module, envir = .s4h_modules, inherits = FALSE)) {
    return(get(module, envir = .s4h_modules, inherits = FALSE))
  }

  imported <- tryCatch(
    reticulate::import(module, delay_load = FALSE, convert = FALSE),
    error = function(e) {
      stop(
        "Could not load the Python module '", module, "'.\n",
        "socio4healthR declares and installs its Python requirements automatically, ",
        "unless a user-selected Python environment overrides the managed environment.\n",
        "Original error: ", conditionMessage(e),
        call. = FALSE
      )
    }
  )

  assign(module, imported, envir = .s4h_modules)
  imported
}

.s4h_check_python <- function(initialize = FALSE) {
  if (isTRUE(initialize)) {
    .s4h_get_module()
  }

  initialized <- reticulate::py_available(initialize = FALSE)
  requirements <- reticulate::py_require()

  if (!initialized) {
    return(list(
      python_initialized = FALSE,
      python_available = FALSE,
      socio4health_available = NA,
      requirements = requirements,
      message = paste(
        "Python has not been initialized.",
        "The managed environment will be provisioned automatically on first use."
      )
    ))
  }

  list(
    python_initialized = TRUE,
    python_available = TRUE,
    socio4health_available = reticulate::py_module_available("socio4health"),
    python_version = as.character(reticulate::py_version()),
    python_executable = reticulate::py_exe(),
    requirements = requirements
  )
}

#' Check Python Environment Status
#'
#' Reports the active Python configuration and the requirements declared by
#' socio4healthR. By default this function does not initialize Python or
#' download dependencies.
#'
#' @param initialize Logical. If `TRUE`, initialize the managed Python
#'   environment and install missing requirements before reporting its status.
#'
#' @return Invisibly returns a list with environment information.
#'
#' @examples
#' s4h_check_env()
#' \dontrun{
#' # Provision the complete Python environment immediately.
#' s4h_check_env(initialize = TRUE)
#' }
#'
#' @export
s4h_check_env <- function(initialize = FALSE) {
  if (!is.logical(initialize) || length(initialize) != 1L || is.na(initialize)) {
    stop("`initialize` must be TRUE or FALSE.", call. = FALSE)
  }

  check_result <- .s4h_check_python(initialize = initialize)

  cat("Python environment status:\n")
  cat("--------------------------\n")

  if (!check_result$python_initialized) {
    cat(check_result$message, "\n")
    cat("Run `s4h_check_env(initialize = TRUE)` to provision it now.\n")
  } else {
    cat("Python is initialized\n")
    cat("  Version: ", check_result$python_version, "\n", sep = "")
    cat("  Executable: ", check_result$python_executable, "\n", sep = "")
    cat(
      "  socio4health: ",
      if (isTRUE(check_result$socio4health_available)) "available" else "not available",
      "\n",
      sep = ""
    )
  }

  invisible(check_result)
}

.onLoad <- function(libname, pkgname) {
  .s4h_prefer_managed_python()
  .s4h_declare_python_requirements()
}
