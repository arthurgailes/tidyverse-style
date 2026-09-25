# tidyverse-style skill

A Claude Code and Codex plugin for the [tidyverse style guide](https://style.tidyverse.org), sourced from [tidyverse/style](https://github.com/tidyverse/style):

- `SKILL.md`: every rule, hand-compacted to about 40% of the original guide.
- `references/*.md`: lossless, mechanically converted chapters.
- `scripts/sync.py`: reports upstream changes and regenerates references.

The skill covers R code and packages, roxygen2, testthat, cli errors, `NEWS.md`, and R project commits and pull requests.

## Installation

**Claude Code**

```text
/plugin marketplace add arthurgailes/tidyverse-style
/plugin install tidyverse-style@tidyverse-style
```

**Codex**

```bash
codex plugin marketplace add arthurgailes/tidyverse-style
codex plugin add tidyverse-style@tidyverse-style
```

**Local project install** (Codex or another agent that reads project skills):

```bash
git clone https://github.com/arthurgailes/tidyverse-style.git .agents/skills/tidyverse-style
```

For agents that use another skill directory, clone there instead or point the agent at
`SKILL.md`. Start a new session after installing. The optional R checker needs `lintr`
and `styler`: `install.packages(c("lintr", "styler"))`.

## What it looks like

Before: a working script with 81 lints in 15 lines (`scripts/check.R`).

```r
library(dplyr); library(ggplot2)
permits.raw = read.csv('data/permits_2024.csv',stringsAsFactors=F)
library(tidyr)
Calc.Growth <- function (x,lag=1){
  if(length(x)<=lag) return(NA_real_)
  out=(x[(lag+1):length(x)]-x[1:(length(x)-lag)])/x[1:(length(x)-lag)]; return(out)
}
clean = permits.raw %>% filter(!is.na(units),units>0) %>% mutate(month=format(as.Date(issue_date),'%Y-%m'),big=ifelse(units>50,T,F)) %>% group_by(msa,month) %>% summarise(total=sum(units),share_mf=mean(structure_type=='multifamily'))
growth = purrr::map(split(clean,clean$msa), ~ Calc.Growth(.x$total))
p <- ggplot(filter(clean,msa %in% c('Houston','Dallas','Austin')),aes(x=month,y=total,colour=msa))+geom_line()+labs(title='Permits',x='Month',y='Units')
if (nrow(clean)>0)
{
    print(p)
} else message('empty')
```

After: the same script, with 0 lints, non-ASCII lines, or styler changes.

```r
library(dplyr)
library(ggplot2)
library(tidyr)

# Load data ---------------------------------------------------------------

permits_raw <- read.csv("data/permits_2024.csv", stringsAsFactors = FALSE)

# Helpers -----------------------------------------------------------------

calc_growth <- function(x, lag = 1) {
  if (length(x) <= lag) {
    return(NA_real_)
  }
  later <- x[(lag + 1):length(x)]
  earlier <- x[1:(length(x) - lag)]
  (later - earlier) / earlier
}

# Clean and summarise -----------------------------------------------------

clean <- permits_raw |>
  filter(!is.na(units), units > 0) |>
  mutate(
    month = format(as.Date(issue_date), "%Y-%m"),
    big = units > 50
  ) |>
  summarise(
    total = sum(units),
    share_mf = mean(structure_type == "multifamily"),
    .by = c(msa, month)
  )

growth <- purrr::map(split(clean, clean$msa), \(x) calc_growth(x$total))

# Plot --------------------------------------------------------------------

p <- clean |>
  filter(msa %in% c("Houston", "Dallas", "Austin")) |>
  ggplot(aes(x = month, y = total, colour = msa)) +
  geom_line() +
  labs(title = "Permits", x = "Month", y = "Units")

if (nrow(clean) > 0) {
  print(p)
} else {
  message("empty")
}
```

What changed:

| Before | After | Rule |
|---|---|---|
| `x = 5`, `'text'`, `T`/`F` | `x <- 5`, `"text"`, `TRUE`/`FALSE` | Syntax: assignment, strings, logicals |
| `%>%`, `~ Calc.Growth(.x$total)` | `\|>`, `\(x) calc_growth(x$total)` | Pipes: magrittr; Functions: anonymous functions |
| `Calc.Growth`, `permits.raw` | `calc_growth`, `permits_raw` | Object names: snake_case, dots reserved for S3 |
| `library(tidyr)` mid-script; `a; b` | All `library()` calls at the top; one statement per line | Files: internal structure; Syntax: semicolons |
| `if(...) return(NA_real_)` on one line; `return(out)` at the end | Early return in its own `{}`; last expression returned implicitly | Control flow modifiers; `return()` |
| One 230-character pipeline | One step per line, one argument per line when a step wraps | Pipes: whitespace and long lines |
| `ggplot(filter(clean, ...), ...)` | Filter in the pipeline, then `ggplot()` | ggplot2: data manipulation before plotting |
| `{` on its own line, 4-space indent, unbraced `else` | `{` ends the line, 2 spaces, `else` on the `}` line, both branches braced | Braced expressions; If statements |
| `ifelse(units > 50, T, F)` | `units > 50` | Not a style rule; the guide's note that `ifelse()` is eager and vectorised made the redundancy obvious |
| No section markers | `# Load data ----` breaks | Files: internal structure |

## Local rules

House rules belong in `SKILL.md` under "Local rules" (currently: ASCII-only `.R` files), so upstream syncs do not confuse them with guide rules.

## Checking R files mechanically

```bash
Rscript scripts/check.R path/to/file.R          # lints, non-ASCII lines, styler dry run
Rscript scripts/check.R --fix path/to/file.R    # restyle in place, then report
Rscript scripts/check.R --json path/to/file.R   # machine-readable findings
```

The checker adds guide rules that lintr disables by default: base pipes, `library()` at the top, no `~ .x` lambdas, `&&`/`||` in conditions, no assignment inside calls, and implicit returns. It also checks ASCII and styler layout, exits 1 on findings, and passes its own check.

## Evaluation

`evals/evals.json` records three Sonnet tasks, each run once with and without the skill (September 2026). Iteration 2 added the checker and reran two tasks.

| Task | Iter 1 with | Iter 1 without | Iter 2 with | Iter 2 without |
|---|---|---|---|---|
| Restyle a messy analysis script | 10/12 | 12/12 | 12/12 | 12/12 |
| Package function with roxygen, tests, NEWS, commit | 11/12 | 12/12 | 11/12 | 10/12 |
| Review a file with 13 planted violations | 13/13 | 13/13 | not rerun | not rerun |

The baseline knew most mechanical rules but missed a 58-character commit subject and a wrapped in-development NEWS bullet. In iteration 1, the skill kept a final `return()`; the checker caught it in iteration 2. The checker cost about 25 seconds and 3,000 tokens per task. Single runs make these results directional.

### Triggering

The description was tuned with skill-creator's optimisation loop: 20 realistic queries (10
should trigger, 10 near-misses such as debugging a join, explaining inherited R code, or a
Python plotting script), 3 runs each, 60/40 train/test split, Fable 5.1. The original
description hit 92% / 83% (train / test), over-triggering on general R help. The tuned one
hit 100% / 100% and names the exclusions explicitly.

## What the conversion does

`references/*.md` differ from the upstream `.qmd` files only in these mechanical ways:

- ```` ```{r} ```` and ```` ```R ```` fences become ```` ```r ````; `#|` chunk options are dropped.
- Heading attributes (`{#sec-files}`, `{-}`) are stripped; `@sec-*` cross references and
  `(#anchor)` links become relative markdown links between the reference files.
- Quarto callouts (`::: {.callout-note}`) become `> **Note:**` blockquotes.
- Upstream editor to-do notes (`<!--# ... -->`) and the knitr chunk that embeds the styler
  screenshot are removed.

Each file starts with a comment naming the exact upstream blob it came from.

## Layout

```
SKILL.md                 the compacted guide (source for both packages)
README.md                this file
.agents/plugins/
  marketplace.json       makes this repo a Codex marketplace
plugin.json              portable Codex plugin manifest
skills/tidyverse-style/  self-contained Codex skill package
.claude-plugin/
  marketplace.json       makes this repo a one-plugin Claude Code marketplace
references/
  UPSTREAM.json          upstream commit, date, and chapter list for references/
  index.md               Welcome
  files.md  syntax.md  functions.md  pipes.md  ggplot2.md        Part: Analyses
  package-files.md  documentation.md  tests.md  errors.md  news.md  Part: Packages
  git.md                 Part: Other
scripts/
  sync.py                fetch, convert, check, mark
  check.R                lintr + styler + ASCII check for .R files
evals/
  evals.json             three eval tasks with assertions
  files/                 input files for the evals
.github/workflows/
  upstream-sync.yml      weekly drift check; opens a PR when upstream moves
upstream/                local clone of tidyverse/style (gitignored)
```

## Licence

The tidyverse style guide is Â© the tidyverse team and licensed
[CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/). `SKILL.md` and
`references/` are adaptations of it and carry the same licence. The sync script is not
derived from the guide.
