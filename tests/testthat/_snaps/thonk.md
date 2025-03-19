# thonk_explain warns when no error info

    Code
      thonk_explain()
    Message
      ! No error information available

# thonk_explain works with error info

    Code
      explanation <- capture.output(res <- thonk_explain())
    Message
      i Click to `fix the issue`.

# thonk_fix fails outside interactive mode

    Code
      thonk_fix()
    Condition
      Error in `thonk_fix()`:
      ! `thonk_fix()` only works interactively.

# thonk_fix errors when no error info

    Code
      thonk_fix()
    Condition
      Error in `thonk_fix()`:
      ! No error information available.

# thonk_fix works with an error without file info

    Code
      explanation <- capture.output(res <- thonk_explain())
    Message
      i Click to `fix the issue`.

