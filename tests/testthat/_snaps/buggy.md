# buggy_explain warns when no error info

    Code
      buggy_explain()
    Message
      ! No error information available

# buggy_explain works with error info

    Code
      explanation <- capture.output(res <- buggy_explain())
    Message
      i Click to `fix the issue`.

# buggy_fix fails outside interactive mode

    Code
      buggy_fix()
    Condition
      Error in `buggy_fix()`:
      ! `buggy_fix()` only works interactively.

# buggy_fix errors when no error info

    Code
      buggy_fix()
    Condition
      Error in `buggy_fix()`:
      ! No error information available.

# buggy_fix works with an error without file info

    Code
      explanation <- capture.output(res <- buggy_explain())
    Message
      i Click to `fix the issue`.

