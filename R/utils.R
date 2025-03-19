.buggy_env <- new_environment()

extract_function_info <- function(call) {
  if (is.null(call)) {
    return(list(func = NULL, pkg = NULL))
  }
  
  func_name <- as.character(call[[1]])
  
  # check if it's a namespaced call (pkg::func)
  if (length(func_name) > 1 && grepl("::", func_name[1])) {
    func <- func_name[3]
    pkg <- func_name[2]
    if (!pkg %in% c("rlang", "base")) {
      return(list(func = func, pkg = pkg))
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

drop_buggy_handlers <- function() {
  current_handlers <- globalCallingHandlers()
  
  if (is.null(current_handlers$error)) {
    return(invisible(NULL))
  }
  
  error_handlers <- current_handlers$error
  handlers_to_keep <- list()
  
  if (is.function(error_handlers)) {
    handler_env <- environment(error_handlers)
    if (!rlang::env_has(handler_env, ".buggy_handler")) {
      handlers_to_keep <- error_handlers
    }
  } else {
    for (i in seq_along(error_handlers)) {
      handler_env <- environment(error_handlers[[i]])
      if (!rlang::env_has(handler_env, ".buggy_handler")) {
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

.stash_last_buggy <- function(x, which) {
  if (!"pkg:buggy" %in% search()) {
    do.call(
      "attach",
      list(new.env(), pos = length(search()), name = "pkg:buggy")
    )
  }
  env <- as.environment("pkg:buggy")
  env_bind(env, !!paste0(".last_buggy_", which) := x)
  invisible(NULL)
}

set_buggy_chat <- function(x) {
  if (is.null(x)) {
    cli_inform(
      c(
        "!" = "buggy requires configuring an ellmer Chat with the
        {col_blue('.buggy_chat')} option.",
        "i" = "Set e.g.
        {.code {col_green('options(.buggy_chat = ellmer::chat_claude(model = \"claude-3-7-sonnet-latest\"))')}}
        in your {.file ~/.Rprofile} and restart R."
      ),
      call = NULL
    )
    return(NULL)
  }

  if (!inherits(x, "Chat")) {
    cli_inform(
      c(
        "!" = "The option {col_blue('.buggy_chat')} must be an ellmer
        Chat object, not {.obj_type_friendly {x}}."
      ),
      call = NULL
    )
    return(NULL)
  }

  res <- x$set_turns(list())$clone()
  env_bind(.buggy_env, chat = res)
  res
}

get_buggy_chat <- function() {
  env_get(.buggy_env, "chat")$clone()
}

# set bindings for later mocking
interactive <- NULL
inherits <- NULL
globalCallingHandlers <- NULL
