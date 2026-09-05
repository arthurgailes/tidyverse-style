library(dplyr); library(ggplot2)
source('helpers.R')
threshold = 0.05
raw_data = read.csv('data/permits_2024.csv', stringsAsFactors=F)
cleaned = raw_data %>% filter(!is.na(units),units>0) %>% mutate(log_units=log(units),month=format(as.Date(issue_date),'%Y-%m')) %>% group_by(msa,month) %>% summarise(total_units=sum(units),n_permits=n(),share_multifamily=mean(structure_type=='multifamily'))
library(tidyr)
wide=cleaned %>% pivot_wider(names_from=month,values_from=total_units)
calc.growth <- function (x,lag=1){
  if(length(x)<=lag) return(NA_real_)
  out = (x[(lag+1):length(x)]-x[1:(length(x)-lag)])/x[1:(length(x)-lag)]
  return(out)
}
for(m in unique(cleaned$msa)) print(m)
big <- ifelse(cleaned$total_units>1000,T,F)
p <- ggplot(filter(cleaned,msa %in% c('Houston','Dallas','Austin')),aes(x=month,y=total_units,colour=msa))+geom_line()+labs(title='Permits',x='Month',y='Units')
if (nrow(cleaned)>0)
{
    message("rows: ",nrow(cleaned))
} else message('empty')
result <- switch(mode, 1, 2, 3)
res = purrr::map(split(cleaned,cleaned$msa), ~ calc.growth(.x$total_units))
cleaned %>% filter(share_multifamily>threshold) -> mf_heavy
print(p);
