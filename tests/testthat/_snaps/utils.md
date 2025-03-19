# set_thonk_chat works

    Code
      res <- set_thonk_chat(NULL)
    Message
      ! thonk requires configuring an ellmer Chat with the .thonk_chat option.
      i Set e.g. `options(.thonk_chat = ellmer::chat_claude(model = "claude-3-7-sonnet-latest"))` in your '~/.Rprofile' and restart R.

---

    Code
      res <- set_thonk_chat("not a chat")
    Message
      ! The option .thonk_chat must be an ellmer Chat object, not a string.

