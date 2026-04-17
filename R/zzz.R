# Internal environment where we store the Python module
.s4h_module <- NULL
.s4h_python_checked <- FALSE

# Internal function: check if Python and socio4health are available
.s4h_check_python <- function() {
  # Check if Python is available at all
  if (!reticulate::py_available()) {
    return(list(
      python_available = FALSE,
      socio4health_available = FALSE,
      message = "Python is not available in your system."
    ))
  }

  # Check if socio4health is installed
  socio4health_available <- reticulate::py_module_available("socio4health")

  return(list(
    python_available = TRUE,
    socio4health_available = socio4health_available,
    python_version = reticulate::py_version(),
    python_executable = reticulate::py_exe()
  ))
}

# Internal function: get the socio4health module (Python)
.s4h_get_module <- function() {
  if (is.null(.s4h_module)) {
    if (!reticulate::py_module_available("socio4health")) {
      stop(
        "The Python module 'socio4health' is not available in the current environment.\n",
        "Manually install the Python package:\n",
        "  pip install socio4health\n",
        "\n",
        "Or configure an existing environment where it is installed:\n",
        "  reticulate::use_condaenv('socio4health', required = TRUE)\n",
        "  reticulate::use_virtualenv('path/to/venv', required = TRUE)\n",
        "  reticulate::use_python('path/to/python.exe', required = TRUE)"
      )
    }
    .s4h_module <<- reticulate::import("socio4health", delay_load = TRUE)
  }
  .s4h_module
}

#' Check Python Environment Status
#'
#' Displays information about the current Python environment and socio4health availability.
#'
#' @return Invisibly returns a list with environment information.
#'
#' @examples
#' \dontrun{
#' s4h_check_env()
#' }
#'
#' @export
s4h_check_env <- function() {
  check_result <- .s4h_check_python()

  cat("Python Environment Status:\n")
  cat(paste(rep("-", nchar("Python Environment Status:")), collapse = ""), "\n")

  if (check_result$python_available) {
    cat("Python is available\n")
    cat("  Python version: ", check_result$python_version, "\n", sep = "")
    cat("  Python executable: ", check_result$python_executable, "\n", sep = "")

    if (check_result$socio4health_available) {
      cat("socio4health is installed and ready to use\n")
    } else {
      cat("socio4health is NOT installed\n")
      cat("  Run: socio4healthR::s4h_setup()\n")
    }
  } else {
    cat("Python is NOT available on your system\n")
    cat("  Please install Python from https://www.python.org/\n")
  }

  invisible(check_result)
}

#' @import reticulate
.onLoad <- function(libname, pkgname) {
  # Configure environment if specified
  if (Sys.getenv("SOCIO4HEALTH_CONDAENV") != "") {
    tryCatch({
      reticulate::use_condaenv(Sys.getenv("SOCIO4HEALTH_CONDAENV"), required = FALSE)
    }, error = function(e) {
      warning("Could not load specified conda environment: ", Sys.getenv("SOCIO4HEALTH_CONDAENV"))
    })
  }

  if (Sys.getenv("SOCIO4HEALTH_VIRTUALENV") != "") {
    tryCatch({
      reticulate::use_virtualenv(Sys.getenv("SOCIO4HEALTH_VIRTUALENV"), required = FALSE)
    }, error = function(e) {
      warning("Could not load specified virtual environment: ", Sys.getenv("SOCIO4HEALTH_VIRTUALENV"))
    })
  }

  if (Sys.getenv("RETICULATE_PYTHON") != "") {
    tryCatch({
      reticulate::use_python(Sys.getenv("RETICULATE_PYTHON"), required = FALSE)
    }, error = function(e) {
      warning("Could not use specified Python executable: ", Sys.getenv("RETICULATE_PYTHON"))
    })
  }

  # Try to load module silently
  .s4h_python_checked <<- TRUE
  tryCatch({
    .s4h_get_module()
  }, error = function(e) {
    # Silently continue; error will be raised when module is actually needed
  })
}
