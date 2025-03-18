test_that("thonk_enable works in interactive mode", {
  local_mocked_bindings(
    interactive = function() TRUE
  )
  
  original_error_handler <- getOption("error")
  
  on.exit({
    options(error = original_error_handler)
  })
  
  expect_silent(thonk_enable())
  
  expect_true(is.function(getOption("error")))
})

test_that("thonk_enable does nothing in non-interactive mode", {
  local_mocked_bindings(
    interactive = function() FALSE
  )
  
  original_error_handler <- getOption("error")
  
  on.exit({
    options(error = original_error_handler)
  })
  
  expect_silent(thonk_enable())
  
  expect_equal(getOption("error"), original_error_handler)
})

test_that("extract_function_info extracts function and package info", {
  mock_call <- quote(dplyr::filter(mtcars, cyl == 8))
  
  local_mocked_bindings(
    format = function(x) {
      if (identical(x, quote(dplyr::filter(mtcars, cyl == 8)))) {
        "dplyr::filter(mtcars, cyl == 8)"
      } else {
        "rlang::trace_back()"
      }
    }
  )
  
  result <- extract_function_info(call = mock_call)
  
  expect_equal(result$func, "filter")
  expect_equal(result$pkg, "dplyr")
})

test_that("extract_file_info extracts file and line info", {
  srcfile <- structure(
    list(filename = "test.R"),
    class = "srcfile"
  )
  
  mock_back_trace <- list(
    src = list(
      NULL,
      structure(c(10, 0, 0, 0), srcfile = srcfile)
    )
  )
  
  result <- extract_file_info(back_trace = mock_back_trace)
  
  expect_equal(result$file, "test.R")
  expect_equal(result$line, 10)
})

test_that("extract_code_blocks extracts R code blocks", {
  markdown_text <- "
Here's an explanation:

```r
# This is R code
x <- 10
y <- 20
```

And more text.
"
  
  result <- extract_code_blocks(markdown_text)
  
  expect_equal(length(result), 1)
  expect_equal(result[[1]], c("# This is R code", "x <- 10", "y <- 20"))
})

test_that("extract_code_blocks handles plain text when no code blocks", {
  plain_text <- "
x <- 10
y <- 20
z <- x + y
"
  
  result <- extract_code_blocks(plain_text)
  
  expect_equal(length(result), 1)
  expect_equal(result[[1]], c("x <- 10", "y <- 20", "z <- x + y"))
})
