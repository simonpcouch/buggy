interactive <- NULL
format <- NULL

#' Troubleshoot errors with LLMs
#'
#' @description
#' The buggy package provides tools for automatically explaining and fixing R
#' errors using large language models (LLMs). When an error occurs, buggy can
#' analyze the error message, backtrace, and context to provide a human-friendly
#' explanation and suggest fixes.
#'
#' * `buggy_enable()`: Attaches a global error handler that captures errors
#'   and provides clickable options to explain or fix them.
#' * `buggy_explain()`: Explains the most recent error using an LLM, offering
#'   detailed context about what went wrong and why.
#' * `buggy_fix()`: Attempts to automatically fix the most recent error by
#'   generating and applying a code fix. If buggy can find the relevant file
#'   lines, it will modify the lines directly. Regardless, it will print the
#'   proposed fix out to the console.
#'
#' @examples
#' \dontrun{
#' # Attach the error handler at the start of your session:
#' buggy_enable()
#' 
#' # Code that will error:
#' sum(1, "n")
#' 
#' # If an error occurs, you'll get interactive links to explain or fix
#' # Alternatively, you can call these functions directly:
#' buggy_explain()
#' buggy_fix()
#' }
#'
#' @name buggy
NULL

#' @param chat An ellmer Chat object to use for interacting with the language model.
#'   If not provided, uses the value from `getOption(".buggy_chat")`.
#'   Set e.g. `options(.buggy_chat = ellmer::chat_claude(model = "claude-3-7-sonnet-latest"))`
#'   in your .Rprofile.
#' @export
#' @rdname buggy
buggy_enable <- function(chat = getOption(".buggy_chat")) {
  set_buggy_chat(chat)

  if (!interactive()) {
    return(invisible(NULL))
  }
  
  # drop any existing buggy handlers
  drop_buggy_handlers()
  
  buggy_handler <- function(cnd) {
    cnd_entraced <- rlang::cnd_entrace(cnd)

    # store error information for later use
    error_msg <- capture.output(print(cnd_entraced))
    back_trace <- cnd_entraced$trace
    
    func_info <- extract_function_info(call = cnd_entraced$call)

    context <- tryCatch({
      # use `eval_bare()` since `btw::btw` will capture the expressions otherwise
      rlang::eval_bare(rlang::call2(
        btw::btw,
        paste0("?", paste0(func_info$pkg, "::", recycle0 = TRUE), func_info$func),
        if (!is.null(func_info$pkg) && !identical(func_info$pkg, "base")) {
          paste0("{", func_info$pkg, "}")
        },
        clipboard = FALSE
      ))
      }, 
      error = function(e) NULL
    )
    
    .buggy_env$last_error <- list(
      error_msg = error_msg,
      backtrace = back_trace,
      context = context
    )

    cnd$use_cli_format <- TRUE
    cnd$footer <- c("i" = format_inline(
      "Click to {.run [explain](buggy::buggy_explain())} or {.run [fix](buggy::buggy_fix())} the last error."
    ))

    rlang::cnd_signal(cnd)
  }
  
  handler_env <- environment(buggy_handler)
  handler_env$.buggy_handler <- TRUE
  
  globalCallingHandlers(error = buggy_handler)
  
  invisible(NULL)
}

#' @export
#' @rdname buggy
buggy_explain <- function() {
  if (!interactive()) {
    return(invisible(NULL))
  }

  if (!env_has(.buggy_env, "last_error")) {
    cli_alert_warning("No error information available")
    return(invisible(NULL))
  }
  
  error_info <- .buggy_env$last_error
  
  prompt <- paste0(c(
    "I encountered the following error:\n",
    error_info$error_msg, 
    "\nBacktrace:\n",
    format(error_info$backtrace),
    if (!is.null(error_info$context)) paste0("\n", error_info$context) else ""
  ), collapse = "\n")
  
  tryCatch({    
    chat <- get_buggy_chat()
    chat$set_system_prompt(paste0(
      readLines(system.file("prompt-explain.md", package = "buggy")), 
      collapse = "\n"
    ))
    
    chat$chat(prompt, echo = TRUE)
    .stash_last_buggy(chat, which = "explain")

    cat_line()
    cli_inform(c(
      "i" = "Click to {.run [fix the issue](buggy::buggy_fix())}."
    ))
  }, error = function(e) {
    cli_inform("Could not generate error explanation.")
  })
  
  invisible(NULL)
}

#' @export
#' @rdname buggy
buggy_fix <- function() {
  if (!interactive()) {
    cli_abort("{.fun buggy_fix} only works interactively.")
    return(invisible(NULL))
  }
  
  if (!exists("last_error", envir = .buggy_env)) {
    cli_abort("No error information available.")
    return(invisible(NULL))
  }

  cli_progress_step("Analyzing error and generating fix...", spinner = TRUE)

  fix_prompt <- "Please generate a fix for this error. Provide only the code that needs to be changed or added, no explanation."
  
  error_info <- .buggy_env$last_error
  chat <- NULL
  if ("pkg:buggy" %in% search()) {
    buggy_env <- as.environment("pkg:buggy")
    if (exists(".last_buggy_explain", envir = buggy_env)) {
      chat <- get(".last_buggy_explain", envir = buggy_env)
    }
  }

  if (!is.null(chat)) {
    fix_code <- chat$chat(fix_prompt, echo = TRUE)
  } else {    
    prompt <- paste0(
      "You are an R programming expert. I encountered the following error:\n\n",
      error_info$error_msg, 
      "\n\nBacktrace:\n",
      format(error_info$backtrace),
      if (!is.null(error_info$context)) paste0("\n\n", error_info$context) else "",
      "\n\n", fix_prompt
    )
    
    chat <- get_buggy_chat()
    fix_code <- chat$chat(prompt, echo = TRUE)
  }

  .stash_last_buggy(chat, which = "fix")
  
  cli_progress_step("Incorporating the fix...", spinner = TRUE)
  file_info <- extract_file_info(back_trace = error_info$backtrace)
  
  if (is.null(file_info$file)) {
    cli_progress_step("Could not determine file to fix.")
    cli_progress_done(result = "failed")
    cat_line(fix_code)
    return(invisible(NULL))
  }

  if (rstudioapi::isAvailable()) {
    context <- rstudioapi::getSourceEditorContext()
    
    if (!is.null(context)) {
      file_content <- context$contents
      error_line <- file_info$line
      
      finder_chat <- get_buggy_chat()
      
      finder_prompt <- paste0(
        "I need to fix a bug in the following R file. The error occurs around line ", 
        error_line - 1, ". ", 
        "The proposed fix is: `", fix_code, "`. ",
        "Please analyze the code and determine how to incorporate the fix. You will supply the exact start and end line indices of the block that needs to be replaced as well as the incorporated fix.\n\n",
        "FILE CONTENT:\n", 
        # actually write out the line numbers for the model
        paste(paste0("[", seq_len(length(file_content)), "] ", file_content), collapse = "\n"),
        "\n\nRETURN FORMAT: Return a JSON object with 'start_line' and 'end_line' as numbers as well as the modified line(s) of code that incorporates the fix. Nothing else. Don't include the bracketed line indices in your response."
      )
      
      tryCatch(
        {
          line_indices_json <- 
            finder_chat$extract_data(
              finder_prompt, 
              type = type_object(
                start_line = type_number("Starting line index"),
                end_line = type_number("Ending line index"),
                fixed_code = type_string("The modified line(s) of code incorporating the fix.")
              )
            )
        },
        error = function(e) {
          cli_progress_step("Could not find the relevant line.")
          cli_progress_done(result = "failed")
          return(invisible(NULL))
        }
      )

      .stash_last_buggy(finder_chat, which = "finder")
      
      range <- rstudioapi::document_range(
        c(line_indices_json$start_line, 1),
        c(line_indices_json$end_line, 1000)
      )
      
      rstudioapi::modifyRange(
        location = range,
        text = line_indices_json$fixed_code
      )
      
      cli_progress_step("Fix applied!")
      cli_progress_done()
    }
  }

  invisible(NULL)
}
