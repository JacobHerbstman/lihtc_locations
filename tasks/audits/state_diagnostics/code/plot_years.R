# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(ggplot2)
x <- fread("../output/state_year_counts.csv")
x <- x[year %in% as.character(1987:2024),lapply(.SD,sum),by=year,.SDcols=c("new_records","first_records","confident_records","new_units","first_units","confident_units")]
x[,year:=as.integer(year)]
d <- melt(x,id.vars="year",variable.name="series")
d[,measure:=ifelse(grepl("units$",series),"Reported units (known counts only)","Project / address records")]
d[,sample:=factor(sub("_(records|units)$","",series),levels=c("new","first","confident"),
  labels=c("All new construction","First address","First address + HUD default"))]
g <- ggplot(d,aes(year,value,color=sample))+geom_line(linewidth=1.1)+
  facet_wrap(~measure,ncol=1,scales="free_y")+
  scale_color_manual(values=c("#152f4c","#dc8b2f","#178578"),name=NULL)+
  scale_x_continuous(breaks=c(1987,1995,2000,2005,2010,2015,2020,2024))+
  scale_y_continuous(labels=function(z) format(z,big.mark=",",scientific=FALSE))+
  labs(title="How much do the two selection steps change the time series?",x="Placed-in-service year",y=NULL,
    subtitle="First address changes the counting rule; the final sample uses HUD coordinates by default.",
    caption="Unknown years and dates after 2024 are omitted here. Unit totals exclude missing or conflicting counts; they are not complete stock estimates.")+
  theme_minimal(base_size=13)+theme(legend.position="bottom",panel.grid.minor=element_blank(),
    plot.title=element_text(face="bold"),strip.text=element_text(face="bold",hjust=0),plot.caption=element_text(hjust=0))
ggsave("../output/annual_comparison.png",g,width=12,height=8,dpi=160,bg="white")
