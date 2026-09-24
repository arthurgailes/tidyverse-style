---
name: tidyverse-style
description: "Apply the tidyverse style guide whenever the deliverable is R code, or text inside an R project, that must follow tidyverse conventions: writing new R functions, scripts, or packages; restyling or cleaning up existing .R files; reviewing R pull requests for style; and answering questions about how R code should be laid out (naming, spacing, indentation, line breaks, pipes, ggplot2 chains, braces, return(), comments). Also covers roxygen2 documentation, testthat file layout, cli error-message wording, NEWS.md bullets, and commit or PR messages for R packages. Do not use when the user only wants existing R code explained or walked through, a runtime error diagnosed, wrong results or empty joins debugged, or R tooling installed, and not for non-R languages or ordinary prose."
metadata:
  upstream: https://github.com/tidyverse/style
  upstream_commit: 2aed77e452a059f4b5c9c4a991d00ea0c5e70cab
  license: CC BY-SA 3.0 (the tidyverse team)
---

# Tidyverse style guide

Complete, compacted version of <https://style.tidyverse.org> (every rule kept; prose and
examples shortened). The verbatim chapters are in `references/*.md`, regenerated from
upstream by `scripts/sync.py`. Style guides are opinionated; the point is consistency, so
fewer decisions are needed. Tools: **styler** restyles code (RStudio add-in); **lintr**
checks it.

## Rules most often missed

Verified failures from agents writing R without this skill:

- Base pipe `|>`, never magrittr `%>%` (R >= 4.3 covers everything recommended).
- 80 characters per line, counted. One-line pipes and `map(xs, \(x) ...)` calls are the usual
  offenders; split them one argument per line, or extract a function.
- Pipe data into `ggplot()`; never filter/slice inside the `data` argument.
- NEWS bullets end `(@user, #issue).` in that order, with the parentheses before the full stop.
  While in development a bullet is one line, however long; wrapping happens at release.
- Commit subject: under 50 characters, sentence case, no period; `Fixes #<n>` (not "Closes")
  in the body.
- `return()`, `stop()`, `break`, `next` always get their own `{}` block, never a one-line `if`.
- Anonymous functions: `\(x) x + 1`, not `~ .x + 1`; never `\()` for multi-line or named functions.
- ASCII only in `.R` files (local rule, below).

## Local rules

Not part of style.tidyverse.org; kept here so they survive upstream syncs. Apply them with
the same force as the guide.

- **ASCII only in R source files.** No character above 0x7F anywhere in a `.R` file: not in
  code, comments, or string literals. That rules out smart quotes, em and en dashes,
  non-breaking spaces, accented letters, box-drawing characters, and emoji, including
  the info and cross bullet glyphs that cli renders (name the bullets `"i"` and `"x"` in
  the cli call and let cli draw them). Files cross Windows and Linux machines with
  different default encodings, `R CMD check` warns on non-ASCII in `R/`, and a stray
  non-breaking space is invisible yet breaks parsing. When a non-ASCII character is
  genuinely needed in a string, write it as an escape: `"\u00e9"` for e-acute,
  `"\u2014"` for an em dash.
  `scripts/check.R` reports every offending line.

---

# Part 1: Analyses

## Files

**Names.** Machine readable: no spaces, symbols, or special characters; all lower case; never
two names differing only in case; words delimited by `-` or `_`; extension `.R`. Human
readable: the name describes the contents (`report-draft-notes.txt`, not `temp.r`); closely
related files share one structure (`fig-eda.png`, `fig-model-3.png`). Sort correctly by
default: dates as `yyyy-mm-dd` (ISO 8601); numbers zero-padded so 11 does not sort before 2;
if order matters, number at the start, not the end (`01-load-data.R`,
`02-exploratory-analysis.R`). If you missed a step, rename all files rather than adding
`02a`, `02b`. Never use "final" or similar in a name; rely on Git, or failing that, date the
file (`report-2022-03-20.qmd`, not `FinalReport-2.qmd`).

```
# Good                          # Bad
fit_models.R                    fit models.R
exploratory-data-analysis.R     ExploratoryDataAnalysis.r
2025-01-01-report.Rmd           jan 01 report.Rmd
```

**Organisation.** If a file can be given a concise name that still evokes its contents, the
organisation is good. Getting there is hard.

**Internal structure.** Break a file into chunks with commented lines of `-` and `=`. Load all
add-on packages together at the very top of the file; do not sprinkle `library()` calls
through the script or hide dependencies in `.Rprofile`.

```r
# Load data ---------------------------

# Plot data ---------------------------
```

## Syntax

### Object names

Only lowercase letters, numbers, and `_`; separate words with `_` (snake case): `day_one`,
`day_1`, not `DayOne`, `dayone`. Reserve `.` for the S3 system (methods are
`function.class`; dots elsewhere give things like `as.data.frame.data.frame()`). If you are
cramming data into names (`model_2018`, `model_2019`), use a list or data frame instead.
Variables are nouns, functions are verbs. Concise and meaningful: `day_one`, not
`first_day_of_the_month` or `djm1`. Do not reuse names of common functions or variables:
never `T <- FALSE`, `c <- 10`, `mean <- function(x) sum(x)`.

### Spacing

- **Commas:** space after, never before: `x[, 1]`, not `x[,1]`, `x[ ,1]`, `x[ , 1]`.
- **Parentheses:** no spaces inside or outside for function calls: `mean(x, na.rm = TRUE)`.
  Space before and after `()` with `if`, `for`, `while`: `if (debug) {`. Space after `()` in
  a function definition: `function(x) {}`, not `function (x) {}` or `function(x){}`.
- **Embracing** `{{ }}` always has inner spaces: `group_by({{ by }})`, not `{{by}}`.
- **Infix operators** (`==`, `+`, `-`, `<-`, `=` in arguments, etc.) always surrounded by
  spaces: `height <- (feet * 12) + inches`. Exceptions, never spaced:
  - high-precedence operators `::`, `:::`, `$`, `@`, `[`, `[[`, `^`, unary `-`, unary `+`,
    `:` (`sqrt(x^2 + y^2)`, `df$z`, `1:10`);
  - single-sided formulas whose right-hand side is a single identifier (`~foo`;
    `tribble(~col1, ~col2, ...)`), but a complex right-hand side does take a space:
    `~ .x + .y`;
  - `!!` and `!!!` in tidy evaluation: `call(!!xyz)`;
  - the help operator: `?mean`, `package?stats`.
- **Extra spaces** are fine to align `=` or `<-` (`mean  = (a + b + c) / n` under
  `total = a + b + c`); never add space where it is not usually allowed.

### Vertical space

Sparingly, to separate "thoughts" like paragraph breaks. No empty lines at the start or end
of a function; a single empty line only where needed to separate functions or pipes; an
empty line before a comment block often helps tie the comment to its code.

### Function calls

- **Named arguments.** Arguments are either *data* or *details*. Omit names of data
  arguments; name every detail argument whose default you override:
  `mean(1:10, na.rm = TRUE)`, not `mean(x = 1:10, , FALSE)`. Never partial-match:
  `rep(1:2, times = 3)`, not `rep(1:2, t = 3)`.
- **Assignment in calls.** Avoid: `x <- f(); if (nzchar(x) < 1)`, not
  `if (nzchar(x <- f()) < 1)`. Only exception: functions that capture side effects,
  `output <- capture.output(x <- f())`.
- **Long calls.** Limit lines to 80 characters; running out of room means extract a
  function or use early returns to reduce nesting. When a call does not fit, one line each
  for the function name, every argument, and the closing `)`:

  ```r
  do_something_very_complicated(
    something = "that",
    requires = many,
    arguments = "some of which may be long"
  )
  ```

  Unnamed common arguments may stay unnamed, but if that makes line lengths very
  uneven, name them anyway (`x = x, y = long_argument_name, ...`). Closely related unnamed
  arguments may share a line, typically so one line of code matches one line of output:

  ```r
  paste0(
    "Requirement: ", requires, "\n",
    "Result: ", result, "\n"
  )
  ```

### Braced expressions

`{}` defines the main hierarchy of R code (function bodies, control flow, calls such as
`tryCatch()` and `test_that()`). `{` is the last character on its line, with the related
code (the `if` clause, function declaration, trailing comma) on that same line; contents
indented two spaces; `}` first character on its line; `else` on the same line as `}`.

```r
if (y < 0 && debug) {
  message("y is negative")
}

test_that("call1 returns an ordered factor", {
  expect_s3_class(call1(x, y), c("factor", "ordered"))
})

tryCatch(
  {
    x <- scan()
    cat("Total: ", sum(x), "\n", sep = "")
  },
  interrupt = function(e) {
    message("Aborted by user")
  }
)
```

An empty braced expression is written `{}` with no space or blank line inside:
`function(...) {}`.

### Control flow

- **Loops** (`for`, `while`, `repeat`): the body must be braced, even one statement.
  A waiting `while` loop may have an empty `{}` body.
- **If statements.** A single-line `if` never contains braces and is only for very simple
  expressions with no side effects and no control-flow change:
  `message <- if (x > 10) "big" else "small"`. Bad: `if (x > 10) { "big" } else { "small" }`;
  `if (x > 0) message <- "big" else message <- "small"`; `if (x > 0) return(x)`. A multi-line
  `if` must use braces (an unbraced `if ... else` over lines only parses inside `{}` or a
  call). Avoid implicit coercion in the condition: `if (length(x) > 0)`, not
  `if (length(x))`. Never `&` or `|` in an `if` condition (they return vectors); always `&&`
  and `||`. `ifelse(x, a, b)` is not a drop-in for `if (x) a else b`: it is vectorised
  (recycles `a`, `b` to `length(x)`) and eager (evaluates both).
- **Control flow modifiers** (`return()`, `stop()`, `break`, `next`) always in their own
  `{}` block:

  ```r
  if (y < 0) {
    stop("Y is negative")
  }
  for (x in xs) {
    if (is_done(x)) {
      break
    }
  }
  ```

- **Switch.** Prefer names to positions (never `switch(y, 1, 2, 3)`). Each element on its
  own line unless all fit on one. Fall-through elements have a space after `=` (`a = ,`).
  Provide a fall-through error unless input was validated earlier:

  ```r
  switch(x,
    a = ,
    b = 1,
    c = 2,
    stop("Unknown `x`", call. = FALSE)
  )
  ```

### Semicolons, assignment, data, comments

- **Semicolons:** never; not at line ends, not to join commands on one line.
- **Assignment:** `<-`, not `=`: `x <- 5`.
- **Strings:** `"` not `'`. Only exception: text containing double quotes and no single
  quotes, `'Text with "quotes"'`. Never `'Text with "double" and \'single\' quotes'`.
- **Logicals:** `TRUE`/`FALSE`, not `T`/`F`.
- **Comments:** every line starts `# ` (symbol plus one space). In analysis code, record
  findings and decisions. If comments are needed to explain *what* the code does, rewrite the
  code; if there are more comments than code, switch to R Markdown/Quarto.

## Functions

- **Naming:** verbs. `add_row()`, `permute()`; not `row_adder()`, `permutation()`.
- **Anonymous functions:** `\(x) x + 1` for short lambdas defined inline in an argument.
  `map(xs, \(x) mean((x + 5)^2))` or `function(x) ...`; not `map(xs, ~ mean((.x + 5)^2))`.
  Never `\()` for multi-line functions (use `function(x) {`) or for named functions
  (`cv <- function(x) {`, not `cv <- \(x) sd(x) / mean(x)`). Avoid `\()` inside a pipe. Use
  informative argument names.
- **Multi-line definitions.** Each argument on its own line, in one of two forms.
  *Single-indent:* arguments indented two spaces, `)` and `{` together on a new line.
  *Hanging-indent:* arguments aligned with the opening `(`, `) {` on the last argument's
  line. Never indent the continuation arguments only two spaces under a hanging first
  argument (hides where the definition ends). An argument that will not fit on one line
  should be reworked to be short and sweet.

  ```r
  # Single-indent
  long_function_name <- function(
    a = "a long argument",
    b = "another argument"
  ) {
    # body indented two spaces as usual
  }

  # Hanging-indent
  long_function_name <- function(a = "a long argument",
                                 b = "another argument") {
    # body
  }

  # Bad: definition and body blur together
  long_function_name <- function(a = "a long argument",
    b = "another argument") {
    # body
  }
  ```

- **S7 methods:** the name is a `method()` call, so use single-indent. If the method call
  itself is too long, spread its arguments over lines with the usual rules, then
  `) <- function(` with single-indent arguments.
- **`return()`:** only for early returns; otherwise rely on the last expression
  (`add_two <- function(x, y) { x + y }`, not `return(x + y)`). A `return()` always gets its
  own braced line (see control flow modifiers). Functions called for side effects (print,
  plot, save) return the first argument `invisible(x)` so they can be piped; `print`
  methods should do this:

  ```r
  print.url <- function(x, ...) {
    cat("Url: ", build_url(x), "\n", sep = "")
    invisible(x)
  }
  ```

- **Comments** in code explain *why*, not what or how (`# Objects like data frames are
  treated as leaves`, not `# Recurse only with bare lists`). Start each line `# `. Sentence
  case. End with a full stop only if the comment has two or more sentences.

## Pipes

- Use `|>` to emphasise a sequence of actions on one object. Works with any function via the
  `_` placeholder: `strings |> gsub("a", "b", x = _)`.
- **Do not pipe** when manipulating more than one object at a time, or when there are
  meaningful intermediate objects worth naming.
- **Whitespace:** space before `|>`, then usually a newline; after the first step, each line
  indented two spaces. Never hang a pipe with unindented continuation lines.
- **Long lines:** when a step's arguments do not fit, one argument per line, indented. In
  data analysis, use the pipe whenever a call spans multiple lines, even for a single step
  (`iris |> summarise(...)`, not `summarise(iris, ...)`).
- **Short pipes** may sit on one line (`iris |> subset(Species == "virginica") |>
  _$Sepal.Length`), but since short pipes grow, prefer one function per line. A short inline
  pipe as an argument is acceptable when it reads better than a lookup
  (`x |> semi_join(y |> filter(is_valid))`); otherwise pull it out and name it:

  ```r
  x_join <- x |> select(a, b, w)
  y_join <- y |> select(a, b, v)
  left_join(x_join, y_join, join_by(a, b))
  ```

- **Assignment**, three acceptable forms: name and `<-` on their own line above the pipe;
  `name <- object |>` on the first line; or `->` at the end (`... |> arrange(-value) ->
  iris_long`). The `->` form is natural to write but harder to read; a leading name acts as a
  heading.
- **magrittr:** use base `|>`, not `%>%`. As of R 4.3.0 the base pipe has every magrittr
  feature that is recommended.

## ggplot2

`+` between layers follows the same rules as `|>`: space before `+`, newline after (even
with two layers), each subsequent line indented two spaces. When the plot follows a dplyr
pipeline, keep a single level of indentation (do not indent the geoms further). When a
layer's arguments do not fit on one line, one argument per line, indented. Do data
manipulation (filter, slice) in the pipeline before plotting, never inside the `data`
argument.

```r
# Good
iris |>
  filter(Species == "setosa") |>
  ggplot(aes(x = Sepal.Width, y = Sepal.Length)) +
  geom_point() +
  labs(
    x = "Sepal width, in cm",
    y = "Sepal length, in cm"
  )

# Bad
ggplot(filter(iris, Species == "setosa"), aes(x = Sepal.Width, y = Sepal.Length)) +
    geom_point()
```

---

# Part 2: Packages

## Package files

Everything in *Files* above applies; in addition: a file with one function takes that
function's name; a file with several related functions takes a concise, evocative name;
deprecated functions live in a file prefixed `deprec-`. Public functions and their
documentation come first, private helpers after all documented functions. Several public
functions sharing one documentation block all immediately follow it:

```r
#' Lots of functions for doing something cool
#'
#' ... Complete documentation ...
#' @name something-cool
NULL

#' @describeIn something-cool Get the mean
#' @export
get_cool_mean <- function(x) {
  # ...
}
```

## Documentation (roxygen2)

Use roxygen2 with markdown enabled; documentation matters even if the only user is
future-you.

- **Title and description.** First line is a concise title (function, dataset, or class),
  sentence case, no trailing full stop. No explicit `@title`/`@description` tags, except
  `@description` when the description has multiple paragraphs or formatting such as a
  bulleted list.
- **Indents and line breaks.** One space after `#'`. Continuation lines of a tag's text get
  two extra spaces (`#'   as column headings.`). Alternatively, multi-line tags
  (`@description`, `@examples`, `@section`) may start on their own line with unindented
  continuation. Blank `#'` lines between sections where needed (`@section Tidy data:` ends
  with a colon).
- **Parameters.** `@param`, `@seealso`, `@return` text is a sentence: capital letter, full
  stop. Shared parameters: `@inheritParams function_to_inherit_from`.
- **Capitalisation and full stops.** Every bullet, enumeration item, and argument description
  is sentence case and ends with a full stop, even if only a few words. Do not capitalise
  function or package names (R is case sensitive). A colon precedes an enumeration or list.
- **Cross-linking.** Encouraged, internal and external. Closely related functions go in
  `@seealso`: a single one as a sentence (`[fct_lump()] to automatically ...`), several as
  a bulleted list. Link other packages fully qualified: `[pkg::function()]`. Related
  families: `@family single table verbs` (family names plural); this auto-generates
  `@seealso` lists. External links: bare URL in `<>` or prose that makes the destination
  obvious; never "click here".
- **R code** in backticks: argument names (`na.rm`), values (`TRUE`, `NA`, `NULL`, `...`),
  literal code, class names (`tbl_df`). Function names may be `` `tibble()` `` but consider
  the link `[tibble()]` instead; link only the first mention per topic.
- **Package names:** no code font. If ambiguous as an ordinary word, follow with "package"
  or wrap in `{}`, not both: "Use the glue package" or "Use {glue}", never "`glue`" or
  "the {glue} package". At the start of a sentence, keep lower case: "dplyr provides ...".
- **Internal functions:** document with `#'` as usual and add `@noRd` so no `.Rd` is
  generated.

## Tests

Test files mirror `R/` files: a function in `R/foofy.R` is tested in
`tests/testthat/test-foofy.R`. Create with `usethis::use_test()`. The file name appears in
test output, giving context.

## Error messages

Assumes `cli::cli_abort()` (bulleted lists, glue interpolation, inline markup, error
chaining, control of the reported call); the advice applies to `stop()` with more work.
Structure: general **problem statement**, then bulleted **details**, then an optional
**hint**.

- **Problem statement.** Concise, informative, sentence case, ends with a full stop. If the
  cause is clear (wrong type or size) use **must**, stating both what was expected and what
  was received: `` `n` must be a numeric vector, not a character vector. ``;
  `` `n` must have length 1, not length 2. `` If you cannot state what was expected use
  **can't**: `` Can't find column `b` in `.data`. ``; `` Can't coerce `.x` to a vector. ``
- **Location.** Ideally name the failing function call (`Error in `validate_mapping()`:`);
  see rlang's error-call topic for passing calls through helpers.
- **Details.** Bulleted list after the statement: cross bullets (`x`) say what is wrong,
  info bullets (`i`) give context. Short sentences: `! Can't subset elements past the end.` /
  `i Location 100 doesn't exist.` / `i There are only 26 elements.` Reveal the location,
  name, or content of the offending input (`x Result 1 is a character vector.`); this may
  mean passing extra arguments so low-level errors know the original source, which is worth
  it for frequently used functions. If the source is unclear, do not guess which argument
  is at fault: `` Can't find column `b` in `.data`. ``, not `` `.data` must contain column `b`. ``;
  `Tibble columns must have compatible sizes.` with per-size bullets, not blaming column `x`.
  Multiple issues or inconsistencies across arguments: one bullet each
  (`` x `.x` has length 4 `` / `` x `.y` has length 2 ``), not one sentence. Truncate long
  lists (`NAs found at 1,000,000 locations: 1, 2, 3, ...`). Pluralise with `ngettext()`
  (see `?ngettext` for translation caveats).
- **Hints.** Only when the cause is clear and common (check patterns of misuse, e.g. on
  StackOverflow). Last bullet, info bullet, ends with a question mark:
  `` i Did you mean `Species == "setosa"`? ``; `` i Did you use `%>%` or `|>` instead of `+`? ``
  Most valuable when the error surfaces far from its root cause (`Can't subset a function.` /
  `` i Have you forgotten to define a variable named `mean`? ``). Bad hints steer users
  wrong, so be conservative.
- **Punctuation.** Sentence case, full stop; bullets likewise, first word capitalised
  unless it is an argument or column name. Prefer the singular in problem statements
  (`Each result must be coercible to a single integer.`, not `Results must be ...`). When
  several problems are detectable, list up to five, then `... and 5 more problems`.
  Connector between problem and location: ", not", ";", or ":" as fits. Argument names in
  backticks; say `` Column `x` `` to distinguish columns from arguments; avoid "variable"
  (ambiguous). Each component under 80 characters; no manual line breaks (wrong at other
  console widths); break into bullets instead, or let cli wrap paragraphs.
- **Before and after** (real tidyverse rewrites): `Argument 2 filter condition does not
  evaluate to a logical vector.` became `Each argument must be a logical vector.` /
  `` * Argument 2 (`cyl`) is an integer vector. ``; `geom_line requires the following
  missing aesthetics: y` became `` `geom_line()` must have the following aesthetics: `y`. ``;
  `` `xxx` contains unknown variables `` and `Evaluation error: object 'xxx' not found.`
  both became `` Can't find column `xxx` in `.data`. ``; `Expected at least one column name;
  e.g. `~name`` became `Must supply at least one column name, e.g. `~name`.`
- **Localisation.** Be informative but keep every sentence simple so messages can be
  translated later, even if you do not localise now.

## NEWS.md

Every user-facing change gets a bullet; minor documentation changes do not, but sweeping
changes and new vignettes do. Write for users, not developers: what changed and why it
matters to them; purely internal changes get no bullet.

- **In development.** New bullets go at the top, directly under the first heading
  (`# pkg (development version)`), as a single line; wrapping and grouping happen at
  release. Include the issue number; for a PR by a non-author, include the GitHub user name.
  Both in parentheses, before the final period:
  `` * `ggsave()` now uses full argument names to avoid partial match warnings (@wch, #2355). ``
- **Pre-release.** Proofread, groom, organise. Function name as close to the start as
  possible (`` `ggsave()` now ... ``, not `Fixed ... in `ggsave()``). Wrap to 80 characters;
  every bullet ends with a full stop. Positive framing and present tense: what now happens
  (`now uses full argument names`), not what used to (`no longer partially matches`). One
  sentence suffices for fixes and minor improvements; new features may need more, and
  complex ones a fenced code example (useful later for the blog post):
  `` * In `stat_bin()`, `binwidth` now also takes functions. The function is called with ``
  `` the scaled `x` values, and should return a single number. ... ``
- **Code style.** Functions, arguments, file names in backticks; functions with `()`; omit
  "the argument"/"the function": `` In `stat_bin()`, `binwidth` now also takes functions. ``
- **Headings.** Level 1 per release: `# modelr 0.1.2`. Small releases need nothing more.
  Many bullets: level 2 groups, commonly `## Breaking changes`, `## New features`,
  `## Minor improvements and fixes`; deviate or subdivide (level 3) when it helps, as
  ggplot2 2.3.0 did (`## New features` > `### Tidy evaluation`, `### sf`, ...). Do not group
  during development. Within a section, order bullets alphabetically by the first function
  mentioned; bullets naming no function go at the top.
- **Breaking changes.** Own section at the top; each bullet describes the symptoms and the
  fix (e.g. condition on `packageVersion("tidyr") > "0.7.2"`), and is repeated in its
  topical section.
- **Common patterns.** New family: describe the behaviour and cite (`@karawoo, #1526`). New
  function: `` * New `stat_qq_line()` makes it easy to ... ``. New argument:
  `` * `geom_segment()` gains a `linejoin` parameter. `` Argument behaviour change:
  `` * In `separate()`, `col = -1` now refers to ... Previously, and incorrectly, ... ``
  Function behaviour change:
  `` * `map()` and `modify()` now work with calls and pairlists (#412). ``
- **Blog post.** Every major and minor release: highlight major user-facing changes with
  examples, point to the release notes for details, skip minor fixes.

---

# Part 3: Git and GitHub

- **Commit messages** follow standard advice (chris.beams.io/posts/git-commit): subject
  line under 50 characters, sentence case, no trailing period; blank line, then explanation
  and context in paragraphs if needed; `Fixes #<issue-number>` when it closes an issue so
  merging to main closes it.
- **Pull requests.** Title briefly describes the change, stands alone, and does not include
  the issue number (no `Fixes #10` in the title). Simple change: description may be blank.
  Complex change: overview of the changes, plus `Fixes #<issue-number>` in the description.

---

## Checking code mechanically

After writing or restyling `.R` files, run the bundled checker if R is available. It applies
lintr's tidyverse defaults plus the guide's non-default rules (base pipe only, `library()`
at the top, no `~ .x` lambdas, `&&`/`||` in conditions, no assignment inside calls,
implicit returns), the local ASCII-only rule, and a styler dry run for layout.

```bash
Rscript scripts/check.R path/to/file.R          # report; exit 1 if anything is off
Rscript scripts/check.R --fix path/to/file.R    # let styler fix layout first, then report
```

Fix what it reports, then re-run until it exits 0. It cannot judge names, comments, roxygen
wording, error-message wording, NEWS, or commits; review those against the sections above.
One known gap: styler puts every `switch()` element on its own line, while the guide allows
one line when all elements fit, so that particular styler diff may be ignored.

## Staying in sync with upstream

`references/` holds the verbatim chapters and `references/UPSTREAM.json` the commit they came
from; `metadata.upstream_commit` above is the commit this file was compacted from.

```bash
python scripts/sync.py            # fetch upstream, regenerate references/, report drift
python scripts/sync.py --check    # exit 1 if references/ or this file are behind upstream
python scripts/sync.py --mark     # after folding upstream changes into this file
```

When the report shows changed chapters, read the printed diff, update the matching section
here (keep every rule, shorten prose), then run `--mark`.
