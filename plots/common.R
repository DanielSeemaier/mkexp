# options(show.error.locations = TRUE)
# options(error = traceback)

DEPS <- c("ggplot2", "plyr", "dplyr", "RColorBrewer", "gridExtra", "egg")
for (dep in DEPS) {
  if (!require(dep, character.only = TRUE, warn.conflicts = FALSE)) {
    install.packages(dep)
  }
}

empty_min <- function(x) {
    if (length(x[!is.na(x)]) > 0) {
        return(min(x, na.rm = TRUE))
    } else {
        return(Inf)
    }
}

weakscaling_aggregator <- function(df) {
  data.frame(
    MinCut = empty_min(df$Cut),
    AvgCut = mean(df$Cut, na.rm = TRUE),
    MinTime = empty_min(df$Time),
    AvgTime = mean(df$Time, na.rm = TRUE),
    MinBalance = empty_min(df$Balance),
    M = max(df$M, na.rm = TRUE),
    N = max(df$N, na.rm = TRUE),
    Timeout = any(as.logical(df$Timeout)) & all(as.logical(df$Timeout) | as.logical(df$Failed)),
    Failed = all(as.logical(df$Failed))
  )
}

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
  if (!("Seed" %in% colnames(df))) {
    df$Seed <- 0
  }

  if (ignore_first_seed) {
    df <- df %>% dplyr::filter(Seed > 0)
  }

  df <- df %>%
    dplyr::mutate(Cut = ifelse(Timeout | Failed, NA, Cut)) %>%
    dplyr::mutate(Balance = ifelse(Timeout | Failed, NA, Balance)) %>%
    dplyr::mutate(Time = ifelse(Timeout, timelimit, Time)) %>%
    dplyr::mutate(Time = ifelse(Failed & !Timeout, NA, Time)) %>%
    dplyr::mutate(Cut = ifelse(Balance > 0.03 + .Machine$double.eps, NA, Cut))

  additional_cols <- c()
  if ("Phase" %in% colnames(df)) {
    additional_cols <- c(additional_cols, "Phase")
  }
  if ("Distance" %in% colnames(df)) {
    additional_cols <- c(additional_cols, "Distance")
  }
  if ("BatchesGain" %in% colnames(df)) {
    additional_cols <- c(additional_cols, "BatchesGain")
  }
  if ("BatchesSize" %in% colnames(df)) {
    additional_cols <- c(additional_cols, "BatchesSize")
  }

  vars <- colnames(df)
  vars <- vars[! vars %in% c("Cut", "Balance", "Time", "Failed", "Timeout", "Seed")]
  #df <- ddply(df, c("Algorithm", "Graph", "K", "Epsilon", "NumPEs", "NumNodes", "NumMPIsPerNode", "NumThreadsPerMPI", additional_cols), aggregator)
  df <- ddply(df, vars, aggregator)

  df <- df %>%
    dplyr::mutate(AvgCut = ifelse(is.na(AvgCut), Inf, AvgCut)) %>%
    dplyr::mutate(MinCut = ifelse(is.na(MinCut), Inf, MinCut)) %>%
    dplyr::mutate(AvgTime = ifelse(is.na(AvgTime), Inf, AvgTime)) %>%
    dplyr::mutate(MinTime = ifelse(is.na(MinTime), Inf, MinTime))

  df <- df %>%
    dplyr::mutate(Infeasible = !Failed & !Timeout & MinBalance > 0.03 + .Machine$double.eps) %>%
    dplyr::mutate(Feasible = !Failed & !Timeout & !Infeasible) %>%
    dplyr::mutate(Invalid = Failed | Timeout | Infeasible)

  return(df)
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
  if (!("Epsilon" %in% colnames(df))) {
    print("Warning: no Epsilon column; default to 3%")
    df$Epsilon <- 0.03
  }
  if (!("Balance" %in% colnames(df)) & "Imbalance" %in% colnames(df)) {
    df$Balance <- df$Imbalance
  } else if (!("Balance" %in% colnames(df))) {
    print("Warning: ignoring balance")
    df$Balance <- df$Epsilon
  }
  if (!("M" %in% colnames(df))) {
    df$M <- -1
  }
  if (!("N" %in% colnames(df))) {
    df$N <- -1
  }

  # Fix imbalance column for ParMETIS (which is 1+x instead if 0+x)
  # if (name == "ParMETIS" & all(df$Balance >= 1.0 || df$Balance == 0)) {
  # df$Balance <- df$Balance - 1
  # }

  df$NumPEs <- df$NumNodes * df$NumMPIsPerNode * df$NumThreadsPerMPI
  df$Algorithm <- name

  df <- aggregate_data(df, 3600, weakscaling_aggregator)

  return(df %>% dplyr::arrange(Graph, K))
}

DEFAULT_ASPECT_RATIO <- 2 / (1 + sqrt(5))

create_theme_facet <- function(aspect_ratio = DEFAULT_ASPECT_RATIO) {
  theme(
    #aspect.ratio = aspect_ratio,
    legend.background = element_blank(),
    legend.title = element_blank(),
    legend.box.spacing = unit(0.1, "cm"),
    legend.title.align = 0.5,
    legend.text = element_text(size = 12, color = "black"),
    plot.title = element_text(size = 14, hjust = 0.5, color = "black"),
    panel.grid.major = element_line(linetype = "11", linewidth = 0.5, color = "grey"),
    panel.grid.minor = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(size = 14),
    axis.line = element_line(linewidth = 0.2, color = "black"),
    axis.title.y = element_text(size = 12, vjust = 1.5, color = "black"),
    axis.title.x = element_text(size = 12, vjust = 1.5, color = "black"),
    axis.text.x = element_text(size = 12, angle = 0, hjust = 0.5, color = "black"),
    axis.text.y = element_text(size = 12, color = "black")
  )
}

create_theme <- function(aspect_ratio = DEFAULT_ASPECT_RATIO) {
  theme(
    aspect.ratio = aspect_ratio,
    legend.background = element_blank(),
    legend.title = element_blank(),
    # legend.margin = margin(-5, 0, 0, 0),
    # legend.spacing.x = unit(0.01, "cm"),
    # legend.spacing.y = unit(0.01, "cm"),
    legend.box.spacing = unit(0.1, "cm"),
    legend.title.align = 0.5,
    legend.text = element_text(size = 8, color = "black"),
    plot.title = element_text(size = 10, hjust = 0.5, color = "black"),
    strip.background = element_blank(),
    strip.text = element_blank(),
    panel.grid.major = element_line(linetype = "11", linewidth = 0.5, color = "grey"),
    panel.grid.minor = element_blank(),
    axis.line = element_line(linewidth = 0.2, color = "black"),
    axis.title.y = element_text(size = 8, vjust = 1.5, color = "black"),
    axis.title.x = element_text(size = 8, vjust = 1.5, color = "black"),
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 8, color = "black"),
    axis.text.y = element_text(size = 8, color = "black")
  )
}
