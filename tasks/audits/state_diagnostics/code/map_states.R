# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
# metric <- "type_missing_pct"
library(data.table)
library(sf)
library(ggplot2)
library(grid)
if (!interactive()) {
  args <- commandArgs(trailingOnly=TRUE)
  stopifnot(length(args)==1L)
  metric <- args[1]
}
stopifnot(metric %in% c("type_missing_pct","coordinates_missing_pct"))
x <- fread("../output/state_summary.csv")
states <- st_read("/vsizip/../input/states.zip",quiet=TRUE)
states <- states[states$STUSPS %in% c(state.abb,"DC"),]
stopifnot(!anyDuplicated(states$STUSPS),!anyDuplicated(x$state),setequal(states$STUSPS,x$state))
states$value <- x[[metric]][match(states$STUSPS,x$state)]
colors <- c("#f4f2e8","#f4ce70","#ea9346","#c64730","#782636")
# Reused for the continental map and both geographically separate insets.
map_panel <- function(z,legend=FALSE) {
  ggplot(z)+geom_sf(aes(fill=value),color="white",linewidth=.35)+
    scale_fill_gradientn(colours=colors,limits=c(0,100),breaks=seq(0,100,20),
      labels=paste0(seq(0,100,20),"%"),name=NULL)+
    theme_void(base_size=14)+theme(legend.position=if(legend) "bottom" else "none",
      legend.key.width=unit(2,"cm"),plot.background=element_rect(fill="white",color=NA))
}
continental <- st_transform(states[!states$STUSPS %in% c("AK","HI"),],5070)
labels <- cbind(st_drop_geometry(continental),st_coordinates(suppressWarnings(st_point_on_surface(continental))))
labels$label <- paste0(labels$STUSPS,"\n",round(labels$value),"%")
small <- c("NH","VT","MA","RI","CT","NJ","DE","MD","DC")
callouts <- labels[match(small,labels$STUSPS),]
callouts$label_y <- seq(2850000,1550000,length.out=nrow(callouts))
main <- map_panel(continental,TRUE)+
  geom_text(data=labels[!labels$STUSPS %in% small,],aes(X,Y,label=label,color=value>55),size=3.5,lineheight=.92)+
  scale_color_manual(values=c("FALSE"="#1e3440","TRUE"="white"),guide="none")+
  geom_segment(data=callouts,aes(x=X,y=Y,xend=2400000,yend=label_y),color="#84929a",linewidth=.25)+
  geom_text(data=callouts,aes(2450000,label_y,label=paste0(STUSPS,"  ",round(value),"%")),hjust=0,size=3.5)+
  coord_sf(xlim=c(-2450000,2850000),ylim=c(100000,3200000),expand=FALSE,datum=NA)
ak <- map_panel(st_transform(states[states$STUSPS=="AK",],3338))
hi <- map_panel(st_transform(states[states$STUSPS=="HI",],3759))
title <- if(metric=="type_missing_pct") "Where is construction type missing?" else "Where are HUD coordinates missing?"
subtitle <- if(metric=="type_missing_pct") "Share of all HUD records with no construction type · 50 states and DC · HUD 2024 release" else "Share of HUD new-construction records without coordinates · 50 states and DC"
png(paste0("../output/",metric,".png"),width=1800,height=1120,res=150)
grid.newpage()
print(main,vp=viewport(x=.5,y=.49,width=.98,height=.83))
print(ak,vp=viewport(x=.13,y=.23,width=.20,height=.22))
print(hi,vp=viewport(x=.31,y=.21,width=.15,height=.11))
grid.text(title,x=.035,y=.965,just="left",gp=gpar(fontsize=23,fontface="bold",col="#152d3b"))
grid.text(subtitle,x=.035,y=.92,just="left",gp=gpar(fontsize=12,col="#435964"))
grid.text(paste0("AK  ",round(states$value[states$STUSPS=="AK"]),"%"),x=.13,y=.105,gp=gpar(fontsize=12))
grid.text(paste0("HI  ",round(states$value[states$STUSPS=="HI"]),"%"),x=.31,y=.14,gp=gpar(fontsize=12))
grid.text("Source: pinned HUD property data; Census 2024 state boundaries. Alaska and Hawaii are resized insets. Values rounded on map.",
  x=.035,y=.025,just="left",gp=gpar(fontsize=9,col="#52616a"))
dev.off()
