test_that("extract_function_info works", {
  expect_equal(extract_function_info(NULL), list(func = NULL, pkg = NULL))
  
  call <- quote(withr::defer("hey there"))
  expect_equal(extract_function_info(call), list(func = "defer", pkg = "withr"))
  
  call <- quote(rlang::sym("x"))
  expect_equal(extract_function_info(call), list(func = NULL, pkg = NULL))
  
  call <- quote(sum(1, 2, 3))
  expect_equal(extract_function_info(call), list(func = "sum", pkg = "base"))
  
  call <- quote(nonexistent_func())
  expect_equal(extract_function_info(call), list(func = "nonexistent_func", pkg = NULL))
})

test_that(".stash_last_thonk works", {
  if ("pkg:thonk" %in% search()) {
    detach("pkg:thonk", character.only = TRUE)
  }
  
  test_value <- list(a = 1, b = 2)
  .stash_last_thonk(test_value, which = "test")
  
  expect_true("pkg:thonk" %in% search())
  env <- as.environment("pkg:thonk")
  expect_true(exists(".last_thonk_test", envir = env))
  expect_equal(get(".last_thonk_test", envir = env), test_value)
  
  detach("pkg:thonk", character.only = TRUE)
})

test_that("set_thonk_chat works", {
  expect_snapshot(res <- set_thonk_chat(NULL))
  expect_snapshot(res <- set_thonk_chat("not a chat"))
  
  skip_if(identical(Sys.getenv("ANTHROPIC_API_KEY"), ""))
  res <- set_thonk_chat(chat_claude(model = "claude-3-7-sonnet-latest"))
  expect_contains(class(res), "R6")
})

test_that("get_thonk_chat works", {
  mock_chat <- list(clone = function() "chat clone")
  mock_env <- new_environment()
  env_bind(mock_env, chat = mock_chat)
  
  local_mocked_bindings(.thonk_env = mock_env)
  
  expect_equal(get_thonk_chat(), "chat clone")
})
