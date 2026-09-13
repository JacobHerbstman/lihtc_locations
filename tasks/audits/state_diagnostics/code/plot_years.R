# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(ggplot2)
x <- fread("../output/state_year_counts.csv")
x <- x[year %in% as.character(1987:2024),lapply(.SD,sum),by=year,.SDcols=c("new_records","selected_records","first_address_records","new_units","selected_units","first_address_units")]
x[,year:=as.integer(year)]
d <- melt(x,id.vars="year",variable.name="series")
d[,measure:=ifelse(grepl("units$",series),"Reported units (known counts only)","Project / address records")]
d[,sample:=factor(sub("_(records|units)$","",series),levels=c("new","selected","first_address"),
  labels=c("All HUD new construction","Main: HUD IDs with coordinates","Comparison: first address"))]
g <- ggplot(d,aes(year,value,color=sample))+
  annotate("rect",xmin=2022.5,xmax=2024.5,ymin=-Inf,ymax=Inf,fill="#f6e4d0",alpha=.7)+
  geom_line(linewidth=1.1)+
  facet_wrap(~measure,ncol=1,scales="free_y")+
  scale_color_manual(values=c("#152f4c","#dc8b2f","#178578"),name=NULL)+
  scale_x_continuous(breaks=c(1987,1995,2000,2005,2010,2015,2020,2024))+
  scale_y_continuous(labels=function(z) format(z,big.mark=",",scientific=FALSE))+
  labs(title="New construction: source coverage and first-address counting",x="Placed-in-service year",y=NULL,
    subtitle="Both located series use each record's own HUD coordinates and units; only the counting rule differs.",
    caption=paste0("Shaded years (2023–2024) are incomplete according to HUD. Unknown years and dates after 2024 are omitted.\n",
                   "Unit sums omit missing counts and are not complete stock estimates; all-ID sums can include repeated financing."))+
  theme_minimal(base_size=13)+theme(legend.position="bottom",panel.grid.minor=element_blank(),
    plot.title=element_text(face="bold"),strip.text=element_text(face="bold",hjust=0),plot.caption=element_text(hjust=0))
ggsave("../output/annual_comparison.png",g,width=12,height=8,dpi=160,bg="white")
