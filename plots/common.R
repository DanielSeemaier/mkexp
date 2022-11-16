options(show.error.locations = TRUE)
options(error = traceback)

DEPS <- c("ggplot2", "plyr", "dplyr", "RColorBrewer", "gridExtra", "egg", "stringr")
for (dep in DEPS) {
    if (!require(dep, character.only = TRUE, warn.conflicts = FALSE)) {
        install.packages(dep)
    }
}

weakscaling_aggregator <- function(df) data.frame(MinCut = min(df$Cut, na.rm = TRUE),
                                                  AvgCut = mean(df$Cut, na.rm = TRUE),
                                                  MinTime = min(df$Time, na.rm = TRUE),
                                                  AvgTime = mean(df$Time, na.rm = TRUE),
                                                  MinBalance = min(df$Balance, na.rm = TRUE),
                                                  M = max(df$M, na.rm = TRUE),
                                                  N = max(df$N, na.rm = TRUE),
                                                  Timeout = any(as.logical(df$Timeout)) & all(as.logical(df$Timeout) | as.logical(df$Failed)),
                                                  Failed = all(as.logical(df$Failed)))

aggregate_data <- function(df, timelimit, aggregator, ignore_first_seed = FALSE) {
    if (!("Timeout" %in% colnames(df))) {
        df$Timeout <- FALSE 
    }
    if (!("Failed" %in% colnames(df))) {
        df$Failed <- FALSE 
    }
    if (!("Epsilon" %in% colnames(df))) {
        df$Epsilon <- 0.03
    }

    if (ignore_first_seed) {
        df <- df %>% dplyr::filter(Seed > 0)
    }

    df <- df %>% dplyr::mutate(Cut = ifelse(Timeout | Failed, NA, Cut)) %>%
        dplyr::mutate(Balance = ifelse(Timeout | Failed, NA, Balance)) %>%
        dplyr::mutate(Time = ifelse(Timeout, timelimit, Time)) %>%
        dplyr::mutate(Time = ifelse(Failed & !Timeout, NA, Time)) %>%
        dplyr::mutate(Cut = ifelse(Balance > 0.03 + .Machine$double.eps, NA, Cut))

    df <- ddply(df, c("Algorithm", "Graph", "K", "Epsilon", "NumPEs", "NumNodes", "NumMPIsPerNode", "NumThreadsPerMPI"), aggregator) 

    df <- df %>% dplyr::mutate(AvgCut = ifelse(is.na(AvgCut), Inf, AvgCut)) %>%
        dplyr::mutate(MinCut = ifelse(is.na(MinCut), Inf, MinCut)) %>%
        dplyr::mutate(AvgTime = ifelse(is.na(AvgTime), Inf, AvgTime)) %>%
        dplyr::mutate(MinTime = ifelse(is.na(MinTime), Inf, MinTime))

    df <- df %>% dplyr::mutate(Infeasible = !Failed & !Timeout & MinBalance > 0.03 + .Machine$double.eps) %>%
        dplyr::mutate(Feasible = !Failed & !Timeout & !Infeasible) %>%
        dplyr::mutate(Invalid = Failed | Timeout | Infeasible)

    return (df)
}

load_data <- function(name, file, seed = 0) {
    df <- read.csv(file)
    df <- df %>% dplyr::filter(Seed >= seed)
    cat("Loaded", nrow(df), "rows from", file, ",", name, "with min seed", seed, "\n")

    # Normalize columns
    if (!("NumNodes" %in% colnames(df))) {
        df$NumNodes <- 1
    }
    if (!("NumMPIsPerNode" %in% colnames(df))) {
        df$NumMPIsPerNode <- 1 
    }
    if (!("NumThreadsPerMPI" %in% colnames(df))) {
        if ("Threads" %in% colnames(df)) {
            df$NumThreadsPerMPI <- df$Threads 
        } else if ("NumThreads" %in% colnames(df)) {
            df$NumThreadsPerMPI <- df$NumThreads
        } else {
            df$NumThreadsPerMPI <- 1
        }
    }
    if (!("Timeout" %in% colnames(df))) {
        df$Timeout <- FALSE 
    }
    if (!("Failed" %in% colnames(df))) {
        df$Failed <- FALSE 
    }

    # Fix imbalance column for ParMETIS (which is 1+x instead if 0+x)
    #if (name == "ParMETIS" & all(df$Balance >= 1.0 || df$Balance == 0)) {
        #df$Balance <- df$Balance - 1 
    #}

    df$NumPEs <- df$NumNodes * df$NumMPIsPerNode * df$NumThreadsPerMPI
    df$Algorithm <- name

    df <- aggregate_data(df, 3600, weakscaling_aggregator)

    # Add columns for legacy performance plots
    if (FALSE) {
        df$avg_km1 <- df$AvgCut
        df$k <- df$K
        df$graph <- df$Graph
        df$timeout <- df$Timeout
        df$failed <- df$Failed
        df$infeasible <- df$Infeasible
        df$algorithm <- df$Algorithm
    }

    return(df %>% dplyr::arrange(Graph, K))
}

DEFAULT_ASPECT_RATIO <- 2 / (1 + sqrt(5))

create_theme <- function(aspect_ratio = DEFAULT_ASPECT_RATIO)
    theme(aspect.ratio = aspect_ratio,
          legend.background = element_blank(),
          legend.title = element_blank(),
          #legend.margin = margin(-5, 0, 0, 0),
          #legend.spacing.x = unit(0.01, "cm"),
          #legend.spacing.y = unit(0.01, "cm"),
          legend.box.spacing = unit(0.1, "cm"),
          legend.title.align = 0.5,
          legend.text = element_text(size = 8, color = "black"), 
          plot.title = element_text(size = 10, hjust = 0.5, color = "black"),
          strip.background = element_blank(),
          strip.text = element_blank(),
          panel.grid.major = element_line(linetype = "11", size = 0.5, color = "grey"),
          panel.grid.minor = element_blank(),
          axis.line = element_line(size = 0.2, color = "black"),
          axis.title.y = element_text(size = 8, vjust = 1.5, color = "black"),
          axis.title.x = element_text(size = 8, vjust = 1.5, color = "black"),
          axis.text.x = element_text(angle = 0, hjust = 0.5, size = 8, color = "black"),
          axis.text.y = element_text(size = 8, color = "black"))

