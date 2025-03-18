
<!-- README.md is generated from README.Rmd. Please edit that file -->

# thonk

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/thonk)](https://CRAN.R-project.org/package=thonk)
<!-- badges: end -->

The goal of thonk is to help users understand and address error messages
using LLMs. With the tool enabled, errors raised to the user are
accompanied by clickable links to “explain” or “fix” the issue.
Explanations are printed to the console while fixes implement changes
directly; in both cases, the model is supplied context about the files
you’re working in and the functions you’re working with.

## Installation

You can install the development version of thonk like so:

``` r
pak::pak("simonpcouch/thonk")
```

To enable thonk, call `thonk::thonk_enable()`. To always have thonk
enabled every time you start R, you could add `thonk::thonk_enable()` to
your `.Rprofile`, perhaps with `usethis::edit_r_profile()`.

## Example

In the following example, I make a mistake when plotting mtcars:

<img src="https://private-user-images.githubusercontent.com/35748691/424200162-aba69171-ab51-48eb-b6b7-b7510537c8c3.mov?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDIzMzM5NDgsIm5iZiI6MTc0MjMzMzY0OCwicGF0aCI6Ii8zNTc0ODY5MS80MjQyMDAxNjItYWJhNjkxNzEtYWI1MS00OGViLWI2YjctYjc1MTA1MzdjOGMzLm1vdj9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTAzMTglMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwMzE4VDIxMzQwOFomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWNlZDcyYjY4ZDAwMTNiMmY4YjNkODA4Njk3YTJkNDBjNTVkYWFiNDUyNTJlODg3MWZhODU1ZmIyYTQ0NjFiNGUmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.JOdBy5KT2xhxpe8ScfEFdKsmRkvLF2ABL57kWUCrmlk" alt="A screencast of a Positron session. A script called example.R is open in the editor with some ggplot2 lines, one of which will cause an error. Running the code results in both an error and a note Click to explain or fix the last error." width="100%" />

Upon seeing the error, I click the “explain” link and, after wrapping my
head around the issue, allow the model to “fix” it. Once the model fixes
the code, it runs correctly.

## Thanks

I’d tossed this package idea around with various folks over the last few
months before deciding to give it a go: namely, Barret Schloerke and
Joshua Yamamoto.
