You are situated inside of an R package source directory. The subdirectory `R/` contains source files. The subdirectory `tests/testthat/` contains corresponding tests. e.g. `R/buggy.R` is tested primarily in `tests/testthat/test-buggy.R`.

Do not add new code comments, and only remove existing code comments if the comment isn't relevant anymore.

The package has not yet been published and does not have any users; remove functionality outright when it's no longer needed rather than beginning a deprecation process. No need to worry about breaking changes.

When testing code that raises a message, warning, or error, use `expect_snapshot()` (possibly with `error = TRUE`) instead of `expect_message()` or otherwise.

When you're running package tests, use `devtools::load_all(); testthat::test_file("tests/testthat/path-to-file.R")`. If you encounter namespacing issues, don't delete tests that otherwise should work, and instead ask me what to do.

Code that I've written previously for a different package that you should model is in `inst/context/`.

Files in `R/` beginning with `import-`, e.g. `import-standalone-types-check.R`, are imported files and ought not to be read.

## Context - ellmer chats

`?`(ellmer::Chat) 

Chat package:ellmer R Documentation

A chat

Description:

```         
 A ‘Chat’ is an sequence of sequence of user and assistant Turns
 sent to a specific Provider. A ‘Chat’ is a mutable R6 object that
 takes care of managing the state associated with the chat; i.e. it
 records the messages that you send to the server, and the messages
 that you receive back. If you register a tool (i.e. an R function
 that the assistant can call on your behalf), it also takes care of
 the tool loop.

 You should generally not create this object yourself, but instead
 call ‘chat_openai()’ or friends instead.
```

Value:

```         
 A Chat object
```

Methods:

Public methods:

```         
     • ‘Chat$new()’

     • ‘Chat$get_turns()’

     • ‘Chat$set_turns()’

     • ‘Chat$add_turn()’

     • ‘Chat$get_system_prompt()’

     • ‘Chat$get_model()’

     • ‘Chat$set_system_prompt()’

     • ‘Chat$tokens()’

     • ‘Chat$last_turn()’

     • ‘Chat$chat()’

     • ‘Chat$chat_parallel()’

     • ‘Chat$extract_data()’

     • ‘Chat$extract_data_parallel()’

     • ‘Chat$extract_data_async()’

     • ‘Chat$chat_async()’

     • ‘Chat$stream()’

     • ‘Chat$stream_async()’

     • ‘Chat$register_tool()’

     • ‘Chat$clone()’
```

Method 'new()':

```         
Usage:

     Chat$new(provider, turns, seed = NULL, echo = "none")
     
Arguments:

     ‘provider’ A provider object.

     ‘turns’ An unnamed list of turns to start the chat with (i.e.,
         continuing a previous conversation). If ‘NULL’ or
         zero-length list, the conversation begins from scratch.

     ‘seed’ Optional integer seed that ChatGPT uses to try and make
         output more reproducible.

     ‘echo’ One of the following options:

           • ‘none’: don't emit any output (default when running in
             a function).

           • ‘text’: echo text output as it streams in (default
             when running at the console).

           • ‘all’: echo all input and output.

         Note this only affects the ‘chat()’ method.
```

Method 'get_turns()':

```         
   Retrieve the turns that have been sent and received so far
   (optionally starting with the system prompt, if any).

Usage:

     Chat$get_turns(include_system_prompt = FALSE)
     

Arguments:

     ‘include_system_prompt’ Whether to include the system prompt
         in the turns (if any exists).
```

Method 'set_turns()':

```         
   Replace existing turns with a new list.

Usage:

     Chat$set_turns(value)
     

Arguments:

     ‘value’ A list of Turns.
```

Method 'add_turn()':

```         
   Add a pair of turns to the chat.

Usage:

     Chat$add_turn(user, system)
     

Arguments:

     ‘user’ The user Turn.

     ‘system’ The system Turn.
```

Method 'get_system_prompt()':

```         
   If set, the system prompt, it not, ‘NULL’.

Usage:

     Chat$get_system_prompt()
     
```

Method 'get_model()':

```         
   Retrieve the model name

Usage:

     Chat$get_model()
     
```

Method 'set_system_prompt()':

```         
   Update the system prompt

Usage:

     Chat$set_system_prompt(value)
     

Arguments:

     ‘value’ A string giving the new system prompt
```

Method 'tokens()':

```         
   List the number of tokens consumed by each assistant turn.
   Currently tokens are recorded for assistant turns only; so user
   turns will have zeros.

Usage:

     Chat$tokens()
     
```

Method 'last_turn()':

```         
   The last turn returned by the assistant.

Usage:

     Chat$last_turn(role = c("assistant", "user", "system"))
     

Arguments:

     ‘role’ Optionally, specify a role to find the last turn with
         for the role.


Returns:

     Either a ‘Turn’ or ‘NULL’, if no turns with the specified role
     have occurred.
```

Method 'chat()':

```         
   Submit input to the chatbot, and return the response as a simple
   string (probably Markdown).

Usage:

     Chat$chat(..., echo = NULL)
     

Arguments:

     ‘...’ The input to send to the chatbot. Can be strings or
         images (see ‘content_image_file()’ and
         ‘content_image_url()’.

     ‘echo’ Whether to emit the response to stdout as it is
         received. If ‘NULL’, then the value of ‘echo’ set when the
         chat object was created will be used.
```

Method 'chat_parallel()':

```         
   *[Experimental]*

   Submit multiple prompts in parallel. Returns a list of Chat
   objects, one for each prompt.

Usage:

     Chat$chat_parallel(prompts, max_active = 10, rpm = 500)
     

Arguments:

     ‘prompts’ A list of user prompts.

     ‘max_active’ The maximum number of simultaenous requests to
         send.

     ‘rpm’ Maximum number of requests per minute.
```

Method 'extract_data()':

```         
   Extract structured data

Usage:

     Chat$extract_data(..., type, echo = "none", convert = TRUE)
     

Arguments:

     ‘...’ The input to send to the chatbot. Will typically include
         the phrase "extract structured data".

     ‘type’ A type specification for the extracted data. Should be
         created with a ‘type_()’ function.

     ‘echo’ Whether to emit the response to stdout as it is
         received. Set to "text" to stream JSON data as it's
         generated (not supported by all providers).

     ‘convert’ Automatically convert from JSON lists to R data
         types using the schema. For example, this will turn arrays
         of objects into data frames and arrays of strings into a
         character vector.
```

Method 'extract_data_parallel()':

```         
   *[Experimental]*

   Submit multiple prompts in parallel. Returns a list of extracted
   data, one for each prompt.

Usage:

     Chat$extract_data_parallel(
       prompts,
       type,
       convert = TRUE,
       max_active = 10,
       rpm = 500
     )
     

Arguments:

     ‘prompts’ A list of user prompts.

     ‘type’ A type specification for the extracted data. Should be
         created with a ‘type_()’ function.

     ‘convert’ Automatically convert from JSON lists to R data
         types using the schema. For example, this will turn arrays
         of objects into data frames and arrays of strings into a
         character vector.

     ‘max_active’ The maximum number of simultaenous requests to
         send.

     ‘rpm’ Maximum number of requests per minute.
```

Method 'extract_data_async()':

```         
   Extract structured data, asynchronously. Returns a promise that
   resolves to an object matching the type specification.

Usage:

     Chat$extract_data_async(..., type, echo = "none")
     

Arguments:

     ‘...’ The input to send to the chatbot. Will typically include
         the phrase "extract structured data".

     ‘type’ A type specification for the extracted data. Should be
         created with a ‘type_()’ function.

     ‘echo’ Whether to emit the response to stdout as it is
         received. Set to "text" to stream JSON data as it's
         generated (not supported by all providers).
```

Method 'chat_async()':

```         
   Submit input to the chatbot, and receive a promise that resolves
   with the response all at once. Returns a promise that resolves
   to a string (probably Markdown).

Usage:

     Chat$chat_async(...)
     

Arguments:

     ‘...’ The input to send to the chatbot. Can be strings or
         images.
```

Method 'stream()':

```         
   Submit input to the chatbot, returning streaming results.
   Returns A coro generator that yields strings. While iterating,
   the generator will block while waiting for more content from the
   chatbot.

Usage:

     Chat$stream(...)
     

Arguments:

     ‘...’ The input to send to the chatbot. Can be strings or
         images.
```

Method 'stream_async()':

```         
   Submit input to the chatbot, returning asynchronously streaming
   results. Returns a coro async generator that yields string
   promises.

Usage:

     Chat$stream_async(...)
     

Arguments:

     ‘...’ The input to send to the chatbot. Can be strings or
         images.
```

Method 'register_tool()':

```         
   Register a tool (an R function) that the chatbot can use. If the
   chatbot decides to use the function, ellmer will automatically
   call it and submit the results back.

   The return value of the function. Generally, this should either
   be a string, or a JSON-serializable value. If you must have more
   direct control of the structure of the JSON that's returned, you
   can return a JSON-serializable value wrapped in ‘base::I()’,
   which ellmer will leave alone until the entire request is
   JSON-serialized.

Usage:

     Chat$register_tool(tool_def)
     

Arguments:

     ‘tool_def’ Tool definition created by ‘tool()’.
```

Method 'clone()':

```         
   The objects of this class are cloneable with this method.

Usage:

     Chat$clone(deep = FALSE)
     

Arguments:

     ‘deep’ Whether to make a deep clone.
```

Examples:

```         
 chat <- chat_openai(echo = TRUE)
 chat$chat("Tell me a funny joke")
 
```
