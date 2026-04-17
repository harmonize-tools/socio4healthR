test_that(".s4h_check_python returns availability status", {
  with_mocked_bindings(
    py_available = function() FALSE,
    .package = "reticulate",
    {
      res <- .s4h_check_python()
      expect_false(res$python_available)
      expect_false(res$socio4health_available)
      expect_match(res$message, "Python is not available")
    }
  )

  with_mocked_bindings(
    py_available = function() TRUE,
    py_module_available = function(x) TRUE,
    py_version = function() "3.10.0",
    py_exe = function() "python",
    .package = "reticulate",
    {
      res <- .s4h_check_python()
      expect_true(res$python_available)
      expect_true(res$socio4health_available)
      expect_equal(res$python_version, "3.10.0")
      expect_equal(res$python_executable, "python")
    }
  )
})

test_that(".s4h_get_module errors when python module is missing", {
  with_mocked_bindings(
    .s4h_module = NULL,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        py_module_available = function(x) FALSE,
        .package = "reticulate",
        {
          expect_error(.s4h_get_module(), "socio4health")
        }
      )
    }
  )
})

test_that(".s4h_get_module imports and caches module", {
  fake_mod <- list(x = 1)

  with_mocked_bindings(
    .s4h_module = NULL,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        py_module_available = function(x) TRUE,
        import = function(...) fake_mod,
        .package = "reticulate",
        {
          res <- .s4h_get_module()
          expect_equal(res$x, 1)
          expect_equal(.s4h_get_module()$x, 1)
        }
      )
    }
  )
})

test_that(".s4h_get_module returns cached module without import", {
  fake_mod <- list(cached = TRUE)
  import_calls <- 0L

  with_mocked_bindings(
    .s4h_module = fake_mod,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        import = function(...) {
          import_calls <<- import_calls + 1L
          list()
        },
        py_module_available = function(x) TRUE,
        .package = "reticulate",
        {
          res <- .s4h_get_module()
          expect_true(isTRUE(res$cached))
          expect_equal(import_calls, 0L)
        }
      )
    }
  )
})

test_that("s4h_check_env prints both available and unavailable branches", {
  with_mocked_bindings(
    .s4h_check_python = function() list(
      python_available = TRUE,
      socio4health_available = TRUE,
      python_version = "3.11.0",
      python_executable = "python"
    ),
    .package = "socio4healthR",
    {
      output <- capture.output(s4h_check_env())
      expect_true(any(grepl("Python is available", output)))
      expect_true(any(grepl("socio4health is installed and ready to use", output)))
    }
  )

  with_mocked_bindings(
    .s4h_check_python = function() list(
      python_available = FALSE,
      socio4health_available = FALSE,
      message = "Python missing"
    ),
    .package = "socio4healthR",
    {
      output <- capture.output(s4h_check_env())
      expect_true(any(grepl("Python is NOT available on your system", output)))
    }
  )
})

test_that(".onLoad handles env vars and warning branches", {
  onload_fun <- get(".onLoad", envir = asNamespace("socio4healthR"))

  with_mocked_bindings(
    .s4h_python_checked = FALSE,
    .s4h_get_module = function() NULL,
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        use_condaenv = function(...) NULL,
        use_virtualenv = function(...) NULL,
        use_python = function(...) NULL,
        .package = "reticulate",
        {
          old_conda <- Sys.getenv("SOCIO4HEALTH_CONDAENV", unset = NA)
          old_venv <- Sys.getenv("SOCIO4HEALTH_VIRTUALENV", unset = NA)
          old_py <- Sys.getenv("RETICULATE_PYTHON", unset = NA)
          on.exit({
            if (is.na(old_conda)) Sys.unsetenv("SOCIO4HEALTH_CONDAENV") else Sys.setenv(SOCIO4HEALTH_CONDAENV = old_conda)
            if (is.na(old_venv)) Sys.unsetenv("SOCIO4HEALTH_VIRTUALENV") else Sys.setenv(SOCIO4HEALTH_VIRTUALENV = old_venv)
            if (is.na(old_py)) Sys.unsetenv("RETICULATE_PYTHON") else Sys.setenv(RETICULATE_PYTHON = old_py)
          }, add = TRUE)

          Sys.setenv(
            SOCIO4HEALTH_CONDAENV = "s4h-conda",
            SOCIO4HEALTH_VIRTUALENV = "s4h-venv",
            RETICULATE_PYTHON = "python.exe"
          )

          expect_silent(onload_fun("socio4healthR", "socio4healthR"))
        }
      )
    }
  )

  with_mocked_bindings(
    .s4h_python_checked = FALSE,
    .s4h_get_module = function() stop("module not available"),
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        use_condaenv = function(...) stop("conda fail"),
        use_virtualenv = function(...) stop("venv fail"),
        use_python = function(...) stop("python fail"),
        .package = "reticulate",
        {
          old_conda <- Sys.getenv("SOCIO4HEALTH_CONDAENV", unset = NA)
          old_venv <- Sys.getenv("SOCIO4HEALTH_VIRTUALENV", unset = NA)
          old_py <- Sys.getenv("RETICULATE_PYTHON", unset = NA)
          on.exit({
            if (is.na(old_conda)) Sys.unsetenv("SOCIO4HEALTH_CONDAENV") else Sys.setenv(SOCIO4HEALTH_CONDAENV = old_conda)
            if (is.na(old_venv)) Sys.unsetenv("SOCIO4HEALTH_VIRTUALENV") else Sys.setenv(SOCIO4HEALTH_VIRTUALENV = old_venv)
            if (is.na(old_py)) Sys.unsetenv("RETICULATE_PYTHON") else Sys.setenv(RETICULATE_PYTHON = old_py)
          }, add = TRUE)

          Sys.setenv(
            SOCIO4HEALTH_CONDAENV = "s4h-conda",
            SOCIO4HEALTH_VIRTUALENV = "s4h-venv",
            RETICULATE_PYTHON = "python.exe"
          )

          warns <- character(0)
          expect_silent(
            withCallingHandlers(
              onload_fun("socio4healthR", "socio4healthR"),
              warning = function(w) {
                warns <<- c(warns, conditionMessage(w))
                invokeRestart("muffleWarning")
              }
            )
          )
          expect_true(any(grepl("Could not load specified conda environment", warns)))
          expect_true(any(grepl("Could not load specified virtual environment", warns)))
          expect_true(any(grepl("Could not use specified Python executable", warns)))
        }
      )
    }
  )
})
