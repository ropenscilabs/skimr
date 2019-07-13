context("Reshaping a skim_df")

test_that("You can parition a skim_df", {
  skimmed <- skim(iris)
  input <- partition(skimmed)
  expect_is(input, "skim_list")
  expect_length(input, 2)
  expect_named(input, c("factor", "numeric"))
  attrs <- attributes(input)
  expect_equal(attrs$data_rows, 150)
  expect_equal(attrs$data_cols, 5)
  expect_identical(attrs$df_name, "`iris`")
  expect_identical(
    attrs$skimmers_used,
    list(
      numeric = c(
        "missing", "complete", "n", "mean", "sd", "p0",
        "p25", "p50", "p75", "p100", "hist"
      ),
      factor = c(
        "missing", "complete", "n", "ordered",
        "n_unique", "top_counts"
      )
    )
  )

  # Subtables
  expect_is(input$factor, c("one_skim_df", "tbl_df", "tbl", "data.frame"))
  expect_n_rows(input$factor, 1)
  expect_n_columns(input$factor, 7)
  expect_named(input$factor, c(
    "skim_variable", "missing", "complete", "n",
    "ordered", "n_unique", "top_counts"
  ))

  expect_is(input$numeric, c("one_skim_df", "tbl_df", "tbl", "data.frame"))
  expect_n_rows(input$numeric, 4)
  expect_n_columns(input$numeric, 12)
  expect_named(input$numeric, c(
    "skim_variable", "missing", "complete", "n", "mean",
    "sd", "p0", "p25", "p50", "p75", "p100",
    "hist"
  ))
})

test_that("Partitioning works in a round trip", {
  skimmed <- skim(iris)
  partitioned <- partition(skimmed)
  input <- bind(partitioned)
  expect_equal(input, skimmed)
})

test_that("You can yank a subtable from a skim_df", {
  skimmed <- skim(iris)
  input <- yank(skimmed, "numeric")
  expect_is(input, c("one_skim_df", "tbl_df", "tbl", "data.frame"))
  expect_n_rows(input, 4)
  expect_n_columns(input, 12)
  expect_named(input, c(
    "skim_variable", "missing", "complete", "n", "mean",
    "sd", "p0", "p25", "p50", "p75", "p100",
    "hist"
  ))
})

test_that("Partition is safe if some skimmers are missing", {
  skimmed <- skim(iris)
  reduced <- dplyr::select(skimmed, skim_variable, skim_type, numeric.missing)
  partitioned <- partition(reduced)
  expect_length(partitioned, 2)
  expect_named(partitioned, c("factor", "numeric"))
  expect_named(partitioned$numeric, c("skim_variable", "missing"))
})

test_that("Partition handles new columns", {
  skimmed <- skim(iris)
  expanded <- dplyr::mutate(
    skimmed,
    mean2 = numeric.mean^2,
    complete2 = numeric.complete^2
  )
  partitioned <- partition(expanded)
  expect_named(partitioned$numeric, c(
    "skim_variable", "missing", "complete", "n", "mean",
    "sd", "p0", "p25", "p50", "p75", "p100",
    "hist", "mean2", "complete2"
  ))
})

test_that("focus() matches select(data, skim_type, skim_variable, ...)", {
  skimmed <- skim(iris)
  expected <- dplyr::select(skimmed, skim_type, skim_variable, numeric.missing)
  expect_identical(focus(skimmed, numeric.missing), expected)
})

test_that("focus() does not allow dropping skim metadata columns", {
  skimmed <- skim(iris)
  expect_error(focus(skimmed, -skim_variable), "Cannot drop")
  expect_error(focus(skimmed, -skim_type), "Cannot drop")
})

test_that("skim_to_wide() returns a deprecation warning", {
  expect_warning(skim_to_wide(iris))
})

test_that("skim_to_list() returns a deprecation warning", {
  expect_warning(skim_to_list(iris))
})

test_that("to_long() returns a long tidy data frame with 4 columns", {
  skimmed_long <- to_long(iris)
  # Statistics from the skim_df  with values of NA are not included
  expect_equal(nrow(skimmed_long), 50)
  expect_equal(
    names(skimmed_long),
    c("skim_type", "skim_variable", "stat", "formatted")
  )
  expect_equal(length(unique(skimmed_long$stat)), 17)
  expect_equal(length(unique(skimmed_long$skim_type)), 2)
  expect_equal(length(unique(skimmed_long$skim_variable)), 5)
})