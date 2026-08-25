test_that("s4h_get_data_info_enum lists supported enums", {
  expect_equal(
    s4h_get_data_info_enum(),
    c("CountryEnum", "NameEnum", "BraColnamesEnum", "BraColspecsEnum")
  )
  expect_error(
    s4h_get_data_info_enum(member = "PNADC"),
    "cannot be supplied"
  )
  expect_error(s4h_get_data_info_enum("UnknownEnum"), "must be one of")
  expect_error(
    s4h_get_data_info_enum("CountryEnum", character()),
    "single non-empty string"
  )
})

test_that("s4h_get_data_info_enum lists members and converts values", {
  fake_members <- list(keys = function() c("PNADC"))
  fake_enum <- list(
    `__members__` = fake_members,
    PNADC = list(value = c("Ano", "UF"))
  )
  fake_module <- list(BraColnamesEnum = fake_enum)

  with_mocked_bindings(
    .s4h_get_module = function(module) {
      expect_equal(module, "socio4health.enums.data_info_enum")
      fake_module
    },
    .package = "socio4healthR",
    {
      with_mocked_bindings(
        iterate = function(x, simplify = FALSE) as.list(x),
        py_to_r = identity,
        .package = "reticulate",
        {
          expect_equal(
            s4h_get_data_info_enum("BraColnamesEnum"),
            "PNADC"
          )
          expect_equal(
            s4h_get_data_info_enum("BraColnamesEnum", "pnadc"),
            c("Ano", "UF")
          )
          expect_error(
            s4h_get_data_info_enum("BraColnamesEnum", "PNAD"),
            "Unknown member"
          )
        }
      )
    }
  )
})
