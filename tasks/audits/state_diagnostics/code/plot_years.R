# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(ggplot2)
x <- fread("../output/state_year_counts.csv")
x <- x[year %in% as.character(1987:2024),lapply(.SD,sum),by=year,.SDcols=c("new_records","hud_coordinate_records","selected_records","new_units","hud_coordinate_units","selected_units")]
x[,year:=as.integer(year)]
d <- melt(x,id.vars="year",variable.name="series")
d[,measure:=ifelse(grepl("units$",series),"Reported units (known counts only)","Project / address records")]
d[,sample:=factor(sub("_(records|units)$","",series),levels=c("new","hud_coordinate","selected"),
  labels=c("All HUD new construction","All IDs with HUD coordinates","First address + HUD coordinates"))]
g <- ggplot(d,aes(year,value,color=sample))+geom_line(linewidth=1.1)+
  facet_wrap(~measure,ncol=1,scales="free_y")+
  scale_color_manual(values=c("#152f4c","#dc8b2f","#178578"),name=NULL)+
  scale_x_continuous(breaks=c(1987,1995,2000,2005,2010,2015,2020,2024))+
  scale_y_continuous(labels=function(z) format(z,big.mark=",",scientific=FALSE))+
  labs(title="New construction: source coverage and first-address counting",x="Placed-in-service year",y=NULL,
    subtitle="Both located series use HUD coordinates only; their difference is the first-address rule.",
    caption="Unknown years and dates after 2024 are omitted here. Unit sums omit missing counts and are not complete stock estimates; all-ID sums can include repeated financing.")+
  theme_minimal(base_size=13)+theme(legend.position="bottom",panel.grid.minor=element_blank(),
    plot.title=element_text(face="bold"),strip.text=element_text(face="bold",hjust=0),plot.caption=element_text(hjust=0))
ggsave("../output/annual_comparison.png",g,width=12,height=8,dpi=160,bg="white")
