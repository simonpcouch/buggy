interactive <- NULL
format <- NULL

#' Troubleshoot errors with LLMs
#'
#' @description
#' The thonk package provides tools for automatically explaining and fixing R
#' errors using large language models (LLMs). When an error occurs, thonk can
#' analyze the error message, backtrace, and context to provide a human-friendly
#' explanation and suggest fixes.
#'
#' * `thonk_enable()`: Attaches a global error handler that captures errors
#'   and provides clickable options to explain or fix them.
#' * `thonk_explain()`: Explains the most recent error using an LLM, offering
#'   detailed context about what went wrong and why.
#' * `thonk_fix()`: Attempts to automatically fix the most recent error by
#'   generating and applying a code fix. If thonk can find the relevant file
#'   lines, it will modify the lines directly. Regardless, it will print the
#'   proposed fix out to the console.
#'
#' @examples
#' \dontrun{
#' # Attach the error handler at the start of your session:
#' thonk_enable()
#' 
#' # Code that will error:
#' sum(1, "n")
#' 
#' # If an error occurs, you'll get interactive links to explain or fix
#' # Alternatively, you can call these functions directly:
#' thonk_explain()
#' thonk_fix()
#' }
#'
#' @name thonk
NULL

#' @export
#' @rdname thonk
thonk_enable <- function() {
  if (!interactive()) {
    return(invisible(NULL))
  }
  
  # drop any existing thonk handlers
  drop_thonk_handlers()
  
  thonk_handler <- function(cnd) {
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
    
    .thonk_env$last_error <- list(
      error_msg = error_msg,
      backtrace = back_trace,
      context = context
    )

    cnd$use_cli_format <- TRUE
    cnd$footer <- c("i" = cli::format_inline(
      "Click to {.run [explain](thonk::thonk_explain())} or {.run [fix](thonk::thonk_fix())} the last error."
    ))

    rlang::cnd_signal(cnd)
  }
  
  handler_env <- environment(thonk_handler)
  handler_env$.thonk_handler <- TRUE
  
  globalCallingHandlers(error = thonk_handler)
  
  invisible(NULL)
}

#' @export
#' @rdname thonk
thonk_explain <- function() {
  if (!interactive()) {
    return(invisible(NULL))
  }

  if (!exists("last_error", envir = .thonk_env)) {
    cli::cli_alert_warning("No error information available")
    return(invisible(NULL))
  }
  
  error_info <- .thonk_env$last_error
  
  prompt <- paste0(
    "I encountered the following error:\n\n",
    error_info$error_msg, 
    "\n\nBacktrace:\n",
    format(error_info$backtrace),
    if (!is.null(error_info$context)) paste0("\n\n", error_info$context) else ""
  )
  
  tryCatch({
    chat <- ellmer::chat_claude(
      model = "claude-3-7-sonnet-latest",
      system_prompt = paste0(readLines(
        system.file("prompt-explain.md", package = "thonk")), 
        collapse = NULL
      )
    )
    
    chat$chat(prompt, echo = TRUE)
    .stash_last_thonk(chat, which = "explain")

    cli::cat_line()
    cli::cli_inform(c(
      "i" = "Click to {.run [fix the issue](thonk::thonk_fix())}."
    ))
  }, error = function(e) {
    message("Could not generate error explanation.")
  })
  
  invisible(NULL)
}

.thonk_env <- new_environment()

extract_function_info <- function(call) {
  if (is.null(call)) {
    return(list(func = NULL, pkg = NULL))
  }
  
  func_name <- as.character(call[[1]])
  
  # check if it's a namespaced call (pkg::func)
  if (length(func_name) > 1 && grepl("::", func_name[1])) {
    parts <- strsplit(func_name[1], "::")[[1]]
    if (length(parts) == 2) {
      pkg <- parts[1]
      func <- parts[2]
      
      if (!pkg %in% c("rlang", "base")) {
        return(list(func = func, pkg = pkg))
      }
    }
  }
  
  # for non-namespaced calls
  if (length(func_name) == 1) {
    func <- func_name[1]
    
    tryCatch({
      func_obj <- match.fun(func)

      if (is_primitive(func_obj)) {
        return(list(func = func, pkg = "base"))
      }
  
      func_env <- environment(func_obj)
      
      if (isNamespace(func_env)) {
        pkg <- environmentName(func_env)
        return(list(func = func, pkg = pkg))
      }
    }, error = function(e) {})
    
    return(list(func = func, pkg = NULL))
  }
  
  list(func = NULL, pkg = NULL)
}

#' @export
#' @rdname thonk
thonk_fix <- function() {
  # TODO: to make this feel snappier, we can generate the fix and the location
  # for it async, perhaps streaming the fix out to the console while doing so.
  if (!interactive()) {
    cli::cli_abort("{.fun thonk_fix} only works interactively.")
    return(invisible(NULL))
  }
  
  if (!exists("last_error", envir = .thonk_env)) {
    cli::cli_abort("No error information available.")
    return(invisible(NULL))
  }
  
  fix_prompt <- "Please generate a fix for this error. Provide only the code that needs to be changed or added, no explanation."
  
  error_info <- .thonk_env$last_error
  chat <- NULL
  if ("pkg:thonk" %in% search()) {
    thonk_env <- as.environment("pkg:thonk")
    if (exists(".last_thonk_explain", envir = thonk_env)) {
      chat <- get(".last_thonk_explain", envir = thonk_env)
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
    
    chat <- ellmer::chat_claude(model = "claude-3-7-sonnet-latest")
    fix_code <- chat$chat(prompt, echo = TRUE)
  }

  .stash_last_thonk(chat, which = "fix")
  
  file_info <- extract_file_info(back_trace = error_info$backtrace)
  
  if (is.null(file_info$file)) {
    cli::cli_warn("Could not determine file to fix.")
    cli::cat_line(fix_code)
    return(invisible(NULL))
  }

  # TODO: this will probably fail for multi-line calls or
  # calls situated within other calls.
  if (rstudioapi::isAvailable()) {
    context <- rstudioapi::getSourceEditorContext()
    
    if (!is.null(context)) {
      file_content <- context$contents
      error_line <- file_info$line
      
      finder_chat <- ellmer::chat_claude(model = "claude-3-7-sonnet-latest")
      
      finder_prompt <- paste0(
        "I need to fix a bug in the following R file. The error occurs around line ", 
        error_line, 
        ". Please analyze the code and determine the exact start and end line indices of the block that needs to be replaced.\n\n",
        "FILE CONTENT:\n", 
        paste(file_content, collapse = "\n"),
        "\n\nRETURN FORMAT: Return only a JSON object with 'start_line' and 'end_line' as numbers. Nothing else."
      )
      
      tryCatch(
        {
          line_indices_json <- 
            finder_chat$extract_data(
              finder_prompt, 
              type = ellmer::type_object(
                start_line = ellmer::type_number("Starting line index"),
                end_line = ellmer::type_number("Ending line index")
              )
            )
        },
        error = function(e) {
          cli::cli_alert_danger("Could not find the relevant line.")
          return(invisible(NULL))
        }
      )

      
      range <- rstudioapi::document_range(
        c(line_indices_json$start_line, 1),
        c(line_indices_json$end_line, 1000)
      )
      
      rstudioapi::modifyRange(
        location = range,
        text = fix_code
      )
    }
  }

  invisible(NULL)
}

extract_file_info <- function(back_trace) {
  srcrefs <- back_trace$src
  
  for (i in seq_along(srcrefs)) {
    if (!is.null(srcrefs[[i]])) {
      file <- attr(srcrefs[[i]], "srcfile")$filename
      if (!is.null(file) && file != "") {
        line <- srcrefs[[i]][1]
        return(list(file = file, line = line))
      }
    }
  }
  
  if (rstudioapi::isAvailable()) {
    context <- rstudioapi::getActiveDocumentContext()
    if (!is.null(context$path) && context$path != "") {
      cursor_pos <- context$selection[[1]]$range$start[1]
      return(list(file = context$path, line = cursor_pos))
    }
  }
  
  list(file = NULL, line = NULL)
}

drop_thonk_handlers <- function() {
  current_handlers <- globalCallingHandlers()
  
  if (is.null(current_handlers$error)) {
    return(invisible(NULL))
  }
  
  error_handlers <- current_handlers$error
  handlers_to_keep <- list()
  
  if (is.function(error_handlers)) {
    handler_env <- environment(error_handlers)
    if (!rlang::env_has(handler_env, ".thonk_handler")) {
      handlers_to_keep <- error_handlers
    }
  } else {
    for (i in seq_along(error_handlers)) {
      handler_env <- environment(error_handlers[[i]])
      if (!rlang::env_has(handler_env, ".thonk_handler")) {
        handlers_to_keep <- c(handlers_to_keep, list(error_handlers[[i]]))
      }
    }
  }
  
  globalCallingHandlers(NULL)
  
  if (length(handlers_to_keep) > 0) {
    if (length(handlers_to_keep) == 1 && !is.list(handlers_to_keep)) {
      globalCallingHandlers(error = handlers_to_keep)
    } else {
      for (handler in handlers_to_keep) {
        globalCallingHandlers(error = handler)
      }
    }
  }
  
  invisible(NULL)
}

.stash_last_thonk <- function(x, which) {
  if (!"pkg:thonk" %in% search()) {
    do.call(
      "attach",
      list(new.env(), pos = length(search()), name = "pkg:thonk")
    )
  }
  env <- as.environment("pkg:thonk")
  env_bind(env, !!paste0(".last_thonk_", which) := x)
  invisible(NULL)
}
