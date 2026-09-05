# Housing affordability index by metro
library(dplyr)
library(readr)

hpi = read_csv("data/hpi.csv")
income <- read_csv('data/income.csv')

afford_index <- function (hpi, income, base_year=2012){
  merged <- hpi %>% inner_join(income, by = c("msa", "year"))
  base <- merged[merged$year==base_year,]
  if(nrow(base) == 0) return(NULL)
  out <- merged %>%
    group_by(msa) %>%
    mutate(index = (median_income / median_price) / (median_income[year == base_year] / median_price[year == base_year]) * 100) %>%
    ungroup()
  return(out)
}

top_metros <- afford_index(hpi, income) %>% filter(year == max(year)) %>% arrange(desc(index)) %>% slice_head(n = 10)

for (m in top_metros$msa) message(m)

label <- if (nrow(top_metros) > 5) { "many" } else { "few" }

mean <- function(x) sum(x) / length(x)

plot_index <- function(df) {
  ggplot2::ggplot(filter(df, year >= 2015), ggplot2::aes(x = year, y = index, colour = msa)) +
    ggplot2::geom_line()
}

scores <- purrr::map_dbl(split(top_metros, top_metros$msa), ~ mean(.x$index))
keep <- scores > 100 & !is.na(scores)
if (keep[1] & keep[2]) message("top two are affordable")
library(ggplot2)
