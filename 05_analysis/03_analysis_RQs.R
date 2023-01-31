library(dplyr)
library(likert)
library(grid)
library(gridExtra)
library(stringr)
library(xlsx)
library(pspearman)
library(cowplot)
library(ggplot2)
library(ggrepel)



############## Data ##############
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
data <- read.csv2("../04_data/questionnaire_data.csv", header = TRUE, quote = "\"", dec = ".", fill = TRUE, comment.char = "")


############## Functions ##############

# Main entry point of the loop. Pre-processes features for the outputting functions. (Factorization, name normalization, current support calculation.)
# featuresC: features - current
# featuresN: features - need
produceOutput <- function(dimension, aspect, features, featuresC, featuresN){
  names(featuresC) <- features
  names(featuresN) <- features
  
  likertC <- likert(featuresC)
  likertN <- likert(featuresN)
  
  current <- likertC$results$always + likertC$results$often
  needs <- likertN$results$`probably useful` + likertN$results$`definitely useful`
  featureCurrent <- data.frame(names(featuresC), current)
  featureNeeds <- data.frame(names(featuresN), needs)
  names(featureCurrent)<-c('feature', 'current')
  names(featureNeeds)<-c('feature', 'needs')
  
  plotLikert(dimension, aspect, features, featuresC, likertC, featuresN, likertN, featureCurrent)
  calculateDiffs(dimension, aspect, features, featuresC, likertC, featuresN, likertN, featureCurrent, featureNeeds)
  index <<- index+1
}


# Generates Likert charts
plotLikert <- function(dimension, aspect, features, featuresC, likertC, featuresN, likertN, featureCurrent){
  featureCurrent <- featureCurrent[order(-featureCurrent$current),]
  
  theme_update(
    legend.text = element_text(size = rel(0.8)),
    legend.title = element_blank(),
    axis.title.x = element_blank(),
    axis.text.y = element_blank()
    )
  
  colors = c("#f72068", "#ffa1c0", "gray", "#9fd7f5", "#42b6f5")
  
  pc <- plot(likertC, group.order = featureCurrent$feature, col = colors) +
    theme(
          plot.margin = unit(c(0,0,0,0), "cm"),
          #panel.border = element_rect(colour = "white", fill=NA, size=2),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          panel.border = element_rect(colour = "grey", fill=NA, size=1)
          )
  pc$layers[[2]]$geom_params$width = 0.6
  pc$layers[[3]]$geom_params$width = 0.6
  pn <- plot(likertN, group.order = featureCurrent$feature, col = colors) + 
    theme(
          plot.margin = unit(c(0,0,0,0), "cm"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          panel.border = element_rect(colour = "grey", fill=NA, size=1)
          )
  pn$layers[[2]]$geom_params$width = 0.6
  pn$layers[[3]]$geom_params$width = 0.6
  
  df <- data.frame()
  ptitle <- ggplot(df) + 
    theme(
      plot.margin = unit(c(0,0,0,0), "cm"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      axis.ticks = element_blank()
    )

  gt1 <- ggplotGrob(pc)
  gt2 <- ggplotGrob(pn)
  gt3 <- ggplotGrob(ptitle)
  newWidth = unit.pmax(gt1$widths[2:3], gt2$widths[2:3], gt3$widths[2:3])
  
  gt1$widths[2:3] = as.list(newWidth)
  gt2$widths[2:3] = as.list(newWidth)
  gt3$widths[2:3] = as.list(newWidth)
  
  fileName = paste("../06_output/likert", paste(paste(str_pad(index, 2, pad="0"), dimension, aspect, sep="__"), "pdf", sep="."), sep="/")
  
  h = 1.2 + length(features)*0.3
  pdf(fileName, height = h, width = 18)
  
  ## Create a graphical object g here
  grid.arrange(gt1, gt3, gt2, ncol=3, widths=c(6,3,6))
  
  ## Stop writing to the PDF file
  dev.off()
}


# Calculates diff in single aspects
calculateDiffs <- function(dimension, aspect, features, featuresC, likertC, featuresN, likertN, featureCurrent, featureNeeds){
  featureCurrent <- featureCurrent[order(featureCurrent$feature),]
  featureNeeds <- featureNeeds[order(featureNeeds$feature),]
  
  
  diff <- data.frame(feature=character(), 
                     current=numeric(),
                     need=numeric(),
                     diff=numeric(),
                     wdiff=numeric(),
                     stringsAsFactors=FALSE)
  
  
  for(i in 1:length(features)){
    diff <- rbind(diff,
                  c(
                    featureNeeds[i,]$feature,
                    featureCurrent[i,]$current,
                    featureNeeds[i,]$needs,
                    difference(featureNeeds[i,]$needs, featureCurrent[i,]$current),
                    expertWeightedDifference(featureNeeds[i,]$needs, featureCurrent[i,]$current)
                  ))
  }
  
  names(diff)<-c('feature', 'current', 'need', 'diff', 'wdiff')
  diff[, 2:5] <- sapply(diff[, 2:5], as.numeric)
  diff <- diff[order(-diff$wdiff),]
  
  diff <- rapply(object = diff, f = round, classes = "numeric", how = "replace", digits = 2)
  
  diffWithDimensionAndAspect <- diff
  diffWithDimensionAndAspect <- data.frame(append(diffWithDimensionAndAspect, c("dimension" = dimension), after = 0))
  diffWithDimensionAndAspect <- data.frame(append(diffWithDimensionAndAspect, c("aspect" = aspect), after = 1))
  names(diffWithDimensionAndAspect)<-c('dimension', 'aspect', 'feature', 'current', 'need', 'diff', 'wdiff')
  allDiffs <<- rbind(allDiffs, diffWithDimensionAndAspect)
  
  cols.dont.want <- "wdiff"
  diff <- diff[, !names(diff) %in% cols.dont.want, drop=F]
}


###### Metrics ########
difference <- function(need, current){
  return(need-current)
}

expertWeightedDifference <- function(need, current){
  return(difference(need, current) * (need/100))
}

############## Main globals ##############
index = 1
allDiffs <-data.frame(dimension=character(),
                      aspect=character(),
                      feature=character(), 
                      current=numeric(),
                      need=numeric(),
                      diff=numeric(),
                      wdiff=numeric(),
                      stringsAsFactors=FALSE)
names(allDiffs)<-c('dimension', 'aspect', 'feature', 'current', 'need', 'diff', 'wdiff')


############## Constants / Data ##############

levelsC <- c("never", "rarely", "sometimes", "often", "always")
levelsN <- c("definitely not useful", "probably not useful", "neutral", "probably useful", "definitely useful")

dimensions <- c(
  "Model_management",
  "Collaboration",
  "Communication"
)

aspects <- list(
  list(
    "Models_and_languages",
    "Model_manipulation",
    "Editors_and_modeling_environments"
  ), 
  list(
    "Stakeholder_management",
    "Collaboration_dynamics",
    "Versioning",
    "Conflicts_and_consistency",
    "Network_architecture_and_robustness"
  ),
  list(
    "Synchronous_communication",
    "Asynchronous_communication",
    "Integration"
  )
)

features <- list(
  list(
    list(
      'Collaboration at model level', 
      'Collaboration at metamodel level',
      'Multi-view modeling',
      'General-purpose modeling languages',
      'Domain-specific modeling languages',
      'Importing external languages into the modeling environment'
    ),
    list(
      "Model validation",
      "Model execution",
      "Model debugging",
      "Model browsing/search",
      "Model testing",
      "Lazy loading of the models/workspace",
      "Round-trip engineering",
      "Code generation",
      "Model transformations",
      "Integration with build/DevOps",
      "Database integration",
      "Metrics of model complexity",
      "Natural Language Processing"
    ),
    list(
      "Visual editors",
      "Textual editors",
      "Tabular editors",
      "Tree-based editors",
      "Sketch-based editors",
      "Editors supporting multiple types of notations",
      "Projectional editing",
      "Desktop-based modeling environment",
      "Web-based modeling environment",
      "Mobile-based modeling environment"
    )
  ),
  list(
    list(
      "RBAC",
      "Authentication/authorization from corporate database",
      "Anonymous access",
      "User identification",
      "User presence visualization"
    ),
    list(
      "Real-time collaboration",
      "Offline collaboration",
      "Human-Machine collaboration"
    ),
    list(
      "Model differencing",
      "Semantic model differencing",
      "Internal versioning",
      "External version control",
      "Model merging",
      "Version branching",
      "Undo-redo",
      "History"
    ),
    list(
      "Locking",
      "Prevention",
      "Conflict awareness",
      "Automation of resolution",
      "Manual resolution",
      "Metrics of degree of conflict/inconsistency",
      "Eventual consistency",
      "Push notifications on conflicts"
    ),
    list(
      "P2P architecture",
      "Cloud-based architecture",
      "Failure recovery"
    )
  ),
  list(
    list(
      "Chat",
      "Audio",
      "Voice",
      "Hand gestures",
      "Face-to-face",
      "Change review sessions",
      "Screen sharing"
    ),
    list(
      "Email",
      "Wiki",
      "Forum",
      "Proposals",
      "Voting",
      "Annotations",
      "Comments",
      "Feedback",
      "Reviews",
      "Call-For-Attention",
      "Sticky notes",
      "Tags",
      "Conflicts table",
      "Multimedia annotations",
      "Commit messages",
      "Integrated professional-social networking"
    ),
    list(
      "Built-in communication tools",
      "External communication tools"
    )
  )
)

d <- list(
  list(
    list(current = data[14:19], need = data[44:49]),
    list(current = data[20:32], need = data[50:62]),
    list(current = data[33:42], need = data[63:72])
  ),
  list(
    list(current = data[74:78], need = data[102:106]),
    list(current = data[79:81], need = data[107:109]),
    list(current = data[82:89], need = data[110:117]),
    list(current = data[90:97], need = data[118:125]),
    list(current = data[98:100], need = data[126:128])
  ),
  list(
    list(current = data[130:136], need = data[156:162]),
    list(current = data[137:152], need = data[163:178]),
    list(current = data[153:154], need = data[179:180])
  )
)

for (i in 1:length(dimensions)){
  for (j in 1:length(aspects[[i]])){
    for (k in 1:length(d[[i]][[j]]$current)){
      d[[i]][[j]]$current[,k] <- factor(d[[i]][[j]]$current[,k], levelsC, ordered = TRUE)
      d[[i]][[j]]$need[,k] <- factor(d[[i]][[j]]$need[,k], levelsN, ordered = TRUE)
    }
  }
}




############## Main ##############
print("Starting...")

outputFolders = c('aggregated', 'aggregated/xlsx', 'likert', 'plots')

for (f in outputFolders){
  folder = paste("../06_output", f, sep="/")
  if(file.exists(folder)){
    unlink(folder, recursive = TRUE)
  }
}

if(!file.exists("../06_output")){
  dir.create("../06_output", showWarnings = FALSE)
}
for (f in outputFolders){
  folder = paste("../06_output", f, sep="/")
  dir.create(folder, showWarnings = FALSE)
}




for (i in 1:length(dimensions)){
  for (j in 1:length(aspects[[i]])){
    #print(paste(i, j, sep="-"))
    produceOutput(dimensions[i], aspects[[i]][[j]], features[[i]][[j]], d[[i]][[j]]$current, d[[i]][[j]]$need)
  }
}


##### Output aggregated need data #####
get_legend<-function(myggplot){
  tmp <- ggplot_gtable(ggplot_build(myggplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

prettyPrint <- function(table, column){
  table[[column]] <- gsub("_", " ", table[[column]])
  return(table)
}

allDiffsToPrint <- allDiffs[order(-allDiffs$wdiff),]
allDiffsToPrint <- prettyPrint(allDiffsToPrint, "dimension")
allDiffsToPrint <- prettyPrint(allDiffsToPrint, "aspect")

write.xlsx(allDiffsToPrint, "../06_output/aggregated/xlsx/Aggregated.xlsx", sheetName = "Sheet1", col.names = TRUE, row.names = FALSE, append = TRUE)

######## Plot current vs need ########
levelsD <- c("Model management", "Collaboration", "Communication")
allDiffsToPrint$dimension <- factor(allDiffsToPrint$dimension, levelsD, ordered = TRUE)

centroids <- aggregate(cbind(allDiffsToPrint$current, allDiffsToPrint$need)~allDiffsToPrint$dimension,allDiffsToPrint,mean)
names(centroids) <- c("dimension", "current", "need")
centroids$dimension <- factor(centroids$dimension, levelsD, ordered = TRUE)

colorPalette=c("#a83287", "#f03a02", "#0af002")
shapes = c(16, 18, 15)
minsegmentlengths = c(0.25, 0.15, 0.25)
fontsizes = c(3, 3, 4)

longNames <- c('Offline collaboration', 'Cloud-based architecture', 'Domain-specific modeling languages', 'Multi-view modeling', 'Natural Language Processing', 'Real-time collaboration', 'External version control', 'Model differencing', 'Semantic model differencing', 'Authentication/authorization from corporate database', 'Editors supporting multiple types of notations', 'Desktop-based modeling environment', 'Mobile-based modeling environment', 'Web-based modeling environment')
shortNames <- c('Offline collab', 'Cloud architecture', 'DSLs', 'MVM', 'NLP', 'Real-time collab', 'External versioning', 'Model diff', 'Semantic diff', 'Auth from corporate DB', 'Editors w/ multiple notations', 'Desktop-based environment', 'Mobile modeling environment', 'Web-based environment')

for (i in 1:length(longNames)){
  x <- allDiffsToPrint[which(allDiffsToPrint$feature==longNames[i]),]
  if(nrow(x) > 0){
    allDiffsToPrint[which(allDiffsToPrint$feature==longNames[i]),]$feature <- shortNames[i]
  }
}

scatterplots <- function(df, title, xtitle, xleft, xright, xMinorBreaks = c(50)){
  for(i in 1:length(dimensions)){
    a <- df[which(df$dimension==levelsD[[i]]),]
    
    p <- ggplot(a, aes(current, need, color=dimension, shape=dimension, fill=dimension)) +
      geom_point(size=2.5) +
      scale_shape_manual(values=shapes[i]) +
      scale_x_continuous(
        breaks=c(25, 75),
        minor_breaks = xMinorBreaks,
        labels=c(xleft, xright),
        limits=c(0,100),
        name = xtitle) +
      scale_y_continuous(
        breaks=c(25, 75),
        minor_breaks = c(50),
        labels=c('less needed', 'more needed'),
        limits=c(0,100),
        name = "Need") +
      scale_color_manual(values=colorPalette[i]) +
      scale_fill_manual(values=colorPalette[i]) +
      theme_minimal() +
      theme(axis.text.y = element_text(angle = 90, hjust = 0.5)) +
      theme(panel.grid.major.x = element_blank()) +
      theme(panel.grid.major.y = element_blank()) +
      theme(panel.border = element_rect(colour = "black", fill=NA, size=0.5)) +
      geom_text_repel(
        label = a$feature,
        size=fontsizes[i],
        colour = "#545454",
        segment.size=0.2,
        segment.curvature = -1e-20,
        segment.ncp = 1,
        segment.angle = 90,
        force_pull = 0,
        min.segment.length = minsegmentlengths[i],
        max.time = 25,
        max.iter = 2500000,
        max.overlaps = 9) +
      theme(legend.position="none")
    
    outputFile <- paste(paste(paste("../06_output/plots/", title, sep=""), tolower(dimensions[[i]]), sep=""), ".pdf", sep="")
    pdf(outputFile, width=7, height=7)
    
    print(p)
    ggsave(outputFile, p)
    
    dev.off()
    
    j = length(plots)
    plots[[j+1]] <- p
  }
}

plots <- c()
scatterplots(allDiffsToPrint, "scatterplot_", "Adoption", "less adopted", "more adopted")


studiesdata <- read.csv2("../04_data/studies_data.csv", header = TRUE, quote = "\"", dec = ".", fill = TRUE, comment.char = "")
rq4df = merge(x=studiesdata,y=allDiffsToPrint[ ,c("feature", "need")], by="feature")


target <- c("Model management", "Collaboration", "Communication")
rq4df <- rq4df[order(match(rq4df[[2]], target)), ]

plots <- c()
scatterplots(rq4df, "scatterplot_rq3_", "Support by academic approaches (relative frequency)", "", "", c())

write.xlsx(rq4df, "../06_output/aggregated/xlsx/Studies.xlsx", sheetName = "Sheet1", col.names = TRUE, row.names = FALSE, append = FALSE)

dev.off()

print("Finished.")