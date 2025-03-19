# set_buggy_chat works

    Code
      res <- set_buggy_chat(NULL)
    Message
      ! buggy requires configuring an ellmer Chat with the .buggy_chat option.
      i Set e.g. `options(.buggy_chat = ellmer::chat_claude(model = "claude-3-7-sonnet-latest"))` in your '~/.Rprofile' and restart R.

---

    Code
      res <- set_buggy_chat("not a chat")
    Message
      ! The option .buggy_chat must be an ellmer Chat object, not a string.

