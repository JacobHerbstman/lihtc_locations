# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(ggplot2)
x <- fread("../output/state_year_counts.csv")
order <- x[,.(rate=sum(type_unknown)/sum(hud_records)),by=state][order(rate),state]
x <- x[year %in% as.character(1987:2024)]
x[,`:=`(year=as.integer(year),state=factor(state,levels=order),missing_pct=fifelse(hud_records>0,100*type_unknown/hud_records,NA_real_))]
g <- ggplot(x,aes(year,state,fill=missing_pct))+geom_tile(color="white",linewidth=.1)+
  scale_fill_gradientn(colours=c("#f4f2e8","#f4ce70","#ea9346","#c64730","#782636"),limits=c(0,100),na.value="#d6dde2",name="Missing type (%)")+
  scale_x_continuous(breaks=c(1987,1995,2000,2005,2010,2015,2020,2024),expand=c(0,0))+
  labs(title="Missing construction type varies by both state and year",subtitle="Each cell is the share missing among that state's HUD records dated to that year.",
    x="Placed-in-service year",y=NULL,caption="Gray = no source records in that state-year. Small state-year counts can produce extreme percentages. Unknown years are in the CSV tables.")+
  theme_minimal(base_size=12)+theme(panel.grid=element_blank(),legend.position="bottom",plot.title=element_text(face="bold"),plot.caption=element_text(hjust=0),axis.text.y=element_text(size=9))
ggsave("../output/type_by_year.png",g,width=11,height=13,dpi=150,bg="white")
