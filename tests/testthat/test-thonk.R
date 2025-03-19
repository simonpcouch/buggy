test_that("thonk_enable works", {
  local_mocked_bindings(
    set_thonk_chat = function(x) TRUE,
    interactive = function() FALSE
  )
  
  expect_equal(thonk_enable(), invisible(NULL))
  
  local_mocked_bindings(
    interactive = function() TRUE,
    drop_thonk_handlers = function() NULL,
    globalCallingHandlers = function(...) NULL
  )
  
  expect_equal(thonk_enable(), invisible(NULL))
})

test_that("thonk_explain warns when no error info", {
  local_mocked_bindings(
    interactive = function() TRUE
  )
  
  mock_env <- new_environment()
  local_mocked_bindings(.thonk_env = mock_env)
  
  expect_snapshot(thonk_explain())
})

test_that("thonk_explain works with error info", {
  skip_if(identical(Sys.getenv("ANTHROPIC_API_KEY"), ""))
  
  local_mocked_bindings(
    interactive = function() TRUE,
    .stash_last_thonk = function(...) NULL
  )
  
  chat <- chat_claude(model = "claude-3-7-sonnet-latest")
  
  mock_error_info <- list(
    error_msg = "Error message",
    backtrace = trace_back(),
    context = "Error context"
  )
  
  mock_env <- new_environment()
  env_bind(mock_env, last_error = mock_error_info)
  
  local_mocked_bindings(
    .thonk_env = mock_env,
    get_thonk_chat = function() chat
  )
  
  expect_snapshot(
    explanation <- capture.output(res <- thonk_explain())
  )
  expect_gte(length(explanation), 1)
})

test_that("thonk_fix fails outside interactive mode", {
  local_mocked_bindings(
    interactive = function() FALSE
  )
  
  expect_snapshot(thonk_fix(), error = TRUE)
})

test_that("thonk_fix errors when no error info", {
  local_mocked_bindings(
    interactive = function() TRUE
  )
  
  mock_env <- new_environment()
  local_mocked_bindings(.thonk_env = mock_env)
  
  expect_snapshot(thonk_fix(), error = TRUE)
})

test_that("thonk_fix works with an error without file info", {
  skip_if(identical(Sys.getenv("ANTHROPIC_API_KEY"), ""))
  
  local_mocked_bindings(
    interactive = function() TRUE,
    extract_file_info = function(...) list(file = NULL, line = NULL),
    .stash_last_thonk = function(...) NULL
  )
  
  chat <- chat_claude(model = "claude-3-7-sonnet-latest")
  
  mock_error_info <- list(
    error_msg = "Error message",
    backtrace = trace_back(),
    context = "Error context"
  )
  
  mock_env <- new_environment()
  env_bind(mock_env, last_error = mock_error_info)
  
  local_mocked_bindings(
    .thonk_env = mock_env,
    get_thonk_chat = function() chat
  )
  
  expect_snapshot(
    explanation <- capture.output(res <- thonk_explain())
  )
  expect_gte(length(explanation), 1)
})
