test_that("Python requirements are declared without initializing Python", {
  captured <- NULL

  with_mocked_bindings(
    py_require = function(packages, python_version) {
      captured <<- list(packages = packages, python_version = python_version)
    },
    .package = "reticulate",
    {
      .s4h_declare_python_requirements()
      expect_equal(
        captured$packages,
        c(
          "socio4health>=1.0.7,<2",
          "pandas>=2,<3",
          "torch==2.8.0; sys_platform == 'win32'",
          "torchvision==0.23.0; sys_platform == 'win32'",
          "torchaudio==2.8.0; sys_platform == 'win32'"
        )
      )
      expect_equal(captured$python_version, ">=3.10,<4")
    }
  )
})

test_that("managed Python is preferred unless the user made a selection", {
  vars <- c(
    "RETICULATE_PYTHON",
    "RETICULATE_PYTHON_ENV",
    "RETICULATE_USE_MANAGED_VENV"
  )
  old <- Sys.getenv(vars, unset = NA_character_)
  restore <- function() {
    for (var in vars) {
      if (is.na(old[[var]])) {
        Sys.unsetenv(var)
      } else {
        do.call(Sys.setenv, stats::setNames(list(old[[var]]), var))
      }
    }
  }

  tryCatch({
    Sys.unsetenv(vars)
    .s4h_prefer_managed_python()
    expect_equal(Sys.getenv("RETICULATE_USE_MANAGED_VENV"), "yes")

    Sys.unsetenv(vars)
    Sys.setenv(RETICULATE_PYTHON_ENV = "custom-python")
    .s4h_prefer_managed_python()
    expect_equal(Sys.getenv("RETICULATE_PYTHON_ENV"), "custom-python")
    expect_equal(Sys.getenv("RETICULATE_USE_MANAGED_VENV"), "")

    Sys.unsetenv(vars)
    Sys.setenv(RETICULATE_USE_MANAGED_VENV = "no")
    .s4h_prefer_managed_python()
    expect_equal(Sys.getenv("RETICULATE_USE_MANAGED_VENV"), "no")
  }, finally = restore())
})

test_that(".s4h_get_module imports with conversion disabled and caches modules", {
  cache <- new.env(parent = emptyenv())
  import_calls <- 0L
  fake_module <- list(value = 1)

  with_mocked_bindings(
    .s4h_modules = cache,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        import = function(module, delay_load, convert) {
          import_calls <<- import_calls + 1L
          expect_equal(module, "socio4health")
          expect_false(delay_load)
          expect_false(convert)
          fake_module
        },
        .package = "reticulate",
        {
          expect_equal(.s4h_get_module()$value, 1)
          expect_equal(.s4h_get_module()$value, 1)
          expect_equal(import_calls, 1L)
        }
      )
    }
  )
})

test_that(".s4h_get_module reports import failures", {
  cache <- new.env(parent = emptyenv())

  with_mocked_bindings(
    .s4h_modules = cache,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        import = function(...) stop("missing module"),
        .package = "reticulate",
        {
          expect_error(.s4h_get_module(), "managed environment")
          expect_error(.s4h_get_module(), "missing module")
        }
      )
    }
  )
})

test_that(".s4h_check_python distinguishes pending and initialized environments", {
  manifest <- list(
    packages = "socio4health>=1.0.7,<2",
    python_version = ">=3.10,<4"
  )

  with_mocked_bindings(
    py_available = function(initialize = FALSE) FALSE,
    py_require = function(...) manifest,
    .package = "reticulate",
    {
      result <- .s4h_check_python()
      expect_false(result$python_initialized)
      expect_match(result$message, "first use")
      expect_equal(result$requirements, manifest)
    }
  )

  with_mocked_bindings(
    py_available = function(initialize = FALSE) TRUE,
    py_module_available = function(module) TRUE,
    py_version = function() "3.12.0",
    py_exe = function() "python",
    py_require = function(...) manifest,
    .package = "reticulate",
    {
      result <- .s4h_check_python()
      expect_true(result$python_initialized)
      expect_true(result$socio4health_available)
      expect_equal(result$python_version, "3.12.0")
    }
  )
})

test_that("s4h_check_env reports status and can initialize", {
  initialized <- FALSE

  with_mocked_bindings(
    .s4h_check_python = function(initialize = FALSE) {
      initialized <<- initialize
      if (!initialize) {
        return(list(
          python_initialized = FALSE,
          message = "Python has not been initialized."
        ))
      }
      list(
        python_initialized = TRUE,
        python_version = "3.12.0",
        python_executable = "python",
        socio4health_available = TRUE
      )
    },
    .package = "socio4healthR",
    {
      output <- capture.output(s4h_check_env())
      expect_false(initialized)
      expect_true(any(grepl("provision it now", output)))

      output <- capture.output(s4h_check_env(initialize = TRUE))
      expect_true(initialized)
      expect_true(any(grepl("socio4health: available", output)))
      expect_error(s4h_check_env(initialize = NA), "TRUE or FALSE")
    }
  )
})

test_that(".onLoad prefers managed Python and declares requirements", {
  calls <- character()
  onload <- get(".onLoad", envir = asNamespace("socio4healthR"))

  with_mocked_bindings(
    .s4h_prefer_managed_python = function() calls <<- c(calls, "managed"),
    .s4h_declare_python_requirements = function() calls <<- c(calls, "requirements"),
    .package = "socio4healthR",
    {
      expect_silent(onload("socio4healthR", "socio4healthR"))
      expect_equal(calls, c("managed", "requirements"))
    }
  )
})
