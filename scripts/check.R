#!/usr/bin/env Rscript
#
# Mechanical check of R files against the tidyverse style guide.
#
#   Rscript scripts/check.R FILE.R [FILE2.R ...]   # lints + styler diff
#   Rscript scripts/check.R --fix FILE.R            # restyle in place
#   Rscript scripts/check.R --json FILE.R           # machine-readable lints
#
# Exit status: 0 if no lints and styler would change nothing, 1 otherwise.
#
# What it covers: lintr's tidyverse defaults (assignment `<-`, 80-char lines,
# double quotes, TRUE/FALSE, snake_case names, spacing, braces, semicolons,
# implicit return) plus the guide's rules that lintr ships but does not
# enable by default: base pipe only, library() calls at the top, no
# assignment inside calls, no `~ .x` lambdas, `&&`/`||` in conditions, no
# `if (x) return()` on one line; the local ASCII-only rule from SKILL.md;
# and a styler dry run showing whether the layout (indentation, line breaks
# around `{`, pipe breaks) matches.
#
# What it cannot check: names being nouns/verbs, comments explaining "why",
# roxygen sentence conventions, error-message wording, NEWS and commit
# style. Those need the reader and SKILL.md.

suppressPackageStartupMessages({
  ok <- requireNamespace("lintr", quietly = TRUE) &&
    requireNamespace("styler", quietly = TRUE)
})
if (!ok) {
  stop("check.R needs the lintr and styler packages: ",
    "install.packages(c('lintr', 'styler'))",
    call. = FALSE
  )
}

args <- commandArgs(trailingOnly = TRUE)
fix <- "--fix" %in% args
json <- "--json" %in% args
files <- setdiff(args, c("--fix", "--json"))
if (json && !requireNamespace("jsonlite", quietly = TRUE)) {
  stop("--json needs the jsonlite package", call. = FALSE)
}
if (length(files) == 0) {
  stop(
    "usage: Rscript scripts/check.R [--fix] [--json] FILE.R ...",
    call. = FALSE
  )
}

linters <- lintr::linters_with_defaults(
  line_length_linter = lintr::line_length_linter(80),
  pipe_consistency_linter = lintr::pipe_consistency_linter("|>"),
  library_call_linter = lintr::library_call_linter(),
  implicit_assignment_linter = lintr::implicit_assignment_linter(),
  unnecessary_lambda_linter = lintr::unnecessary_lambda_linter(),
  vector_logic_linter = lintr::vector_logic_linter(),
  if_not_else_linter = lintr::if_not_else_linter(),
  # The guide: return(), stop(), break, next always get their own braced block.
  # lintr has no linter for that, so it is approximated by the two below.
  return_linter = lintr::return_linter(return_style = "implicit"),
  brace_linter = lintr::brace_linter(allow_single_line = FALSE)
)

ascii_msg <- "Only ASCII characters are allowed in R files."
status <- 0L
all_lints <- list()
all_non_ascii <- list()

for (f in files) {
  if (!file.exists(f)) {
    message("check.R: no such file: ", f)
    status <- 1L
    next
  }
  if (fix) {
    styler::style_file(f, style = styler::tidyverse_style)
  }

  lints <- lintr::lint(f, linters = linters)
  all_lints[[f]] <- lints
  if (length(lints) > 0) status <- 1L

  original <- enc2utf8(readLines(f, warn = FALSE, encoding = "UTF-8"))
  styled <- enc2utf8(as.character(
    styler::style_text(original, style = styler::tidyverse_style)
  ))
  changed <- sum(!(styled %in% original)) + sum(!(original %in% styled))

  # Local rule (SKILL.md "Local rules"): .R files are ASCII only.
  non_ascii <- which(is.na(iconv(original, from = "UTF-8", to = "ASCII")))
  if (length(non_ascii) > 0) status <- 1L
  all_non_ascii[[f]] <- non_ascii

  if (!json) {
    cat(sprintf(
      "== %s: %d lint%s, %d non-ASCII line%s, styler would change %d line%s\n",
      f, length(lints), if (length(lints) == 1) "" else "s",
      length(non_ascii), if (length(non_ascii) == 1) "" else "s",
      changed, if (changed == 1) "" else "s"
    ))
    if (length(lints) > 0) print(lints)
    for (i in non_ascii) {
      cat(sprintf(
        "%s:%d: style: [non_ascii] %s\n%s\n", f, i, ascii_msg, original[i]
      ))
    }
    if (changed > 0 && !fix) {
      status <- 1L
      cat("-- styler diff (run with --fix to apply):\n")
      # Fall back to a plain listing when diffobj is absent.
      if (requireNamespace("diffobj", quietly = TRUE)) {
        print(diffobj::diffChr(original, styled,
          mode = "unified",
          format = "raw", pager = "off"
        ))
      } else {
        cat(paste0("- ", original[!(original %in% styled)]), sep = "\n")
        cat(paste0("+ ", styled[!(styled %in% original)]), sep = "\n")
      }
    }
  } else if (changed > 0) {
    status <- 1L
  }
}

if (json) {
  out <- lapply(names(all_lints), function(f) {
    l <- all_lints[[f]]
    lints <- lapply(l, function(x) {
      list(
        file = f, line = x$line_number, column = x$column_number,
        linter = x$linter, message = x$message
      )
    })
    ascii <- lapply(all_non_ascii[[f]], function(i) {
      list(
        file = f, line = i, column = 1L,
        linter = "non_ascii", message = ascii_msg
      )
    })
    c(lints, ascii)
  })
  json_out <- unlist(out, recursive = FALSE)
  cat(jsonlite::toJSON(json_out, auto_unbox = TRUE, pretty = TRUE), "\n")
}

quit(status = status)
