#!/usr/bin/env Rscript
source("common.R")

create_performance_profile <- function(...,
                                       column.objective = "AvgCut",
                                       column.algorithm = "Algorithm",
                                       column.timeout = "Timeout",
                                       column.infeasible = "Infeasible",
                                       column.failed = "Failed",
                                       primary_key = c("Graph", "K"),
                                       segments = list(
                                         list(
                                           trans = "identity",
                                           to = 1.1,
                                           width = 3,
                                           breaks = seq(1.0, 1.1, by = 0.01),
                                           labels = c("1.0", "", "", "", "", "1.05", "", "", "", "", "1.1")
                                         ),
                                         list(
                                           trans = "identity",
                                           to = 2,
                                           width = 2,
                                           breaks = c(1.25, 1.5, 1.75, 2),
                                           labels = c("", "1.5", "", "2")
                                         ),
                                         list(
                                           trans = "log10",
                                           to = 100,
                                           width = 1,
                                           breaks = c(10, 100),
                                           labels = c("10^1", "10^2")
                                         )
                                       ),
                                       segment.errors.width = 1,
                                       tick.timeout = "auto",
                                       tick.infeasible = "auto",
                                       tick.failed = "auto",
                                       label.pdf.timeout = "timeout",
                                       label.pdf.infeasible = "infeasible",
                                       label.pdf.failed = "failed",
                                       colors = c(),
                                       tiny = FALSE) {
  all_datasets <- list(...)
  stopifnot(length(all_datasets) > 0)

  # Replace all 0s by 1s in each dataset
  for (i in 1:length(all_datasets)) {
    all_datasets[[i]][[column.objective]] <- 
        ifelse(all_datasets[[i]][[column.objective]] == 0, 1, all_datasets[[i]][[column.objective]])
  }

  # Sort by primary key
  for (dataset in all_datasets) {
    dataset <- dataset %>% dplyr::arrange_at(primary_key)
  }

  # Check for consistent data
  first_dataset <- all_datasets[[1]]
  for (dataset in all_datasets) {
    stopifnot(column.objective %in% colnames(dataset))
    stopifnot(column.algorithm %in% colnames(dataset))
    stopifnot(column.timeout %in% colnames(dataset))
    stopifnot(column.infeasible %in% colnames(dataset))
    stopifnot(!(NA %in% dataset[[column.objective]]))
    stopifnot(!(-Inf %in% dataset[[column.objective]]))
    stopifnot(nrow(dataset) == nrow(first_dataset))
    stopifnot(dataset[, primary_key] == first_dataset[, primary_key])
  }

  # Compute performance profile ratios
  best <- do.call(pmin, lapply(all_datasets, \(df) df[[column.objective]]))
  all_ratios <- lapply(all_datasets, \(df) df[[column.objective]] / best)

  # Compute performance profile rates
  PSEUDO_RATIO_TIMEOUT <- 1000000
  PSEUDO_RATIO_INFEASIBLE <- 2000000
  PSEUDO_RATIO_FAILED <- 3000000
  num_rows <- nrow(first_dataset)

  pp_data <- data.frame()
  for (i in 1:(length(all_datasets))) {
    dataset <- all_datasets[[i]]
    ratios <- all_ratios[[i]]

    pp_data <- data.frame(Ratio = ratios) %>%
      dplyr::mutate(Ratio = ifelse(dataset[[column.timeout]], PSEUDO_RATIO_TIMEOUT, Ratio)) %>%
      dplyr::mutate(Ratio = ifelse(dataset[[column.infeasible]], PSEUDO_RATIO_INFEASIBLE, Ratio)) %>%
      dplyr::mutate(Ratio = ifelse(dataset[[column.failed]] & !dataset[[column.timeout]], PSEUDO_RATIO_FAILED, Ratio)) %>%
      dplyr::group_by(Ratio) %>%
      dplyr::summarise(N = dplyr::n()) %>%
      dplyr::arrange(Ratio) %>%
      dplyr::mutate(Fraction = cumsum(N) / num_rows) %>%
      dplyr::mutate(Algorithm = dataset[[column.algorithm]][1]) %>%
      dplyr::mutate(Transformed = 0) %>%
      rbind(pp_data)
  }

  # Scale ratios to respect the segments
  offset <- 0
  from <- 1
  for (segment in segments) {
    min_value <- do.call(segment$trans, list(from))
    max_value <- do.call(segment$trans, list(segment$to))
    span <- max_value - min_value

    pp_data <- pp_data %>%
      dplyr::mutate(Transformed = ifelse(Transformed == 0 & Ratio >= from & Ratio < segment$to, 1, Transformed)) %>%
      dplyr::mutate(Ratio = ifelse(Transformed == 1,
        offset + segment$width * (do.call(segment$trans, list(Ratio)) - min_value) / span,
        Ratio
      )) %>%
      dplyr::mutate(Transformed = ifelse(Transformed == 1, 2, Transformed))

    offset <- offset + segment$width
    from <- segment$to
  }

  # Map errors (infeasible, timeout, failed)
  map_errors <- function(vals) {
    sapply(vals, \(val) if (val == PSEUDO_RATIO_TIMEOUT) {
      2
    } else if (val == PSEUDO_RATIO_INFEASIBLE) {
      1
    } else if (val == PSEUDO_RATIO_FAILED) {
      1
    } else if (val == Inf) {
      2
    } else {
      0
    })
  }
  pp_data <- pp_data %>%
    dplyr::mutate(Transformed = ifelse(Transformed == 0 & Ratio >= from, 1, Transformed)) %>%
    dplyr::mutate(Ratio = ifelse(Transformed == 1,
      offset + segment.errors.width * map_errors(Ratio) / 2,
      Ratio
    )) %>%
    dplyr::mutate(Transformed = ifelse(Transformed == 1, 2, Transformed))
  stopifnot(pp_data %>% dplyr::filter(Transformed != 2) %>% nrow() == 0)

  # Generate x axis breaks and labels
  x_breaks <- c()
  x_labels <- c()
  offset <- 0
  from <- 1.0
  for (segment in segments) {
    stopifnot(length(segment$labels) == length(segment$breaks))

    min_value <- do.call(segment$trans, list(from))
    max_value <- do.call(segment$trans, list(segment$to))
    span <- max_value - min_value

    x_breaks <- c(x_breaks, sapply(segment$breaks, \(v) offset + segment$width * (do.call(segment$trans, list(v)) - min_value) / span))
    x_labels <- c(x_labels, segment$labels)

    offset <- offset + segment$width
    from <- segment$to
  }
  x_breaks <- c(x_breaks, c(offset + 1 / 2, offset + 1))
  x_labels <- c(x_labels, c(label.pdf.infeasible, label.pdf.timeout))

  # Draw plot
  y_labels <- if (tiny) c("0.0", "", "0.2", "", "0.4", "", "0.6", "", "0.8", "", "1.0") else seq(0.0, 1.0, by = 0.1)

  p <- ggplot(pp_data, aes(x = Ratio, y = Fraction, color = Algorithm)) +
    scale_x_continuous(expand = c(0, 0.01), breaks = x_breaks, labels = x_labels) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0.01), breaks = seq(0.0, 1.0, by = 0.1), labels = y_labels) +
    geom_step(linewidth = 1.5)

  x <- 0
  for (segment in segments) {
    x <- x + segment$width
    p <- p + geom_vline(xintercept = x)
  }

  # Set colors
  if (length(colors) > 0) {
    p <- p + scale_color_manual(name = "Algorithm", values = colors)
  }

  return(p)
}
