#!/usr/bin/env Rscript
source("common.R")

show_timeouts <- function(df, option) option == "always" || (option == "auto" && any(df$Timeout))
show_infeasibles <- function(df, option) option == "always" || (option == "auto" && any(df$Infeasible)) 
show_fails <- function(df, option) option == "always" || (option == "auto" && any(df$Failed))

create_running_time_boxplot <- function(...,
                                        column.time = "AvgTime", 
                                        column.algorithm = "Algorithm", 
                                        column.timeout = "Timeout",
                                        column.infeasible = "Infeasible",
                                        column.failed = "Failed",
                                        primary_key = c("Graph", "K"),
                                        tick.timeout = "auto", 
                                        tick.infeasible = "auto",
                                        tick.failed = "make_infeasible",
                                        tick.errors.space_below = 0.8,
                                        tick.errors.space_between = 0.8,
                                        label.pdf.timeout = PDF_LABEL_TIMEOUT,
                                        label.pdf.infeasible = PDF_LABEL_INFEASIBLE,
                                        label.pdf.failed = PDF_LABEL_FAILED,
                                        label.tex.timeout = TEX_LABEL_TIMEOUT,
                                        label.tex.infeasible = TEX_LABEL_INFEASIBLE,
                                        label.tex.failed = TEX_LABEL_FAILED,
                                        colors = c(),
                                        levels = c(),
                                        annotation = data.frame(),
                                        tex = FALSE,
                                        position.y = "left",
                                        tiny = FALSE) {
    all_datasets <- list(...)
    stopifnot(length(all_datasets) > 0)

    # Sort by primary key
    for (dataset in all_datasets) {
        dataset <- dataset %>% dplyr::arrange_at(primary_key)
    }

    # Check for consistent data
    first_dataset <- all_datasets[[1]]
    for (dataset in all_datasets) {
        stopifnot(column.time %in% colnames(dataset))
        stopifnot(column.algorithm %in% colnames(dataset))
        stopifnot(column.timeout %in% colnames(dataset))
        stopifnot(column.infeasible %in% colnames(dataset))
        stopifnot(!(NaN %in% dataset[[column.time]]))
        stopifnot(!(NA %in% dataset[[column.time]]))
        stopifnot(!(-Inf %in% dataset[[column.time]]))
        stopifnot(!(0 %in% dataset[[column.time]]))
        stopifnot(nrow(dataset) == nrow(first_dataset))
        stopifnot(dataset[, primary_key] == first_dataset[, primary_key])
    }

    # Merge data to one data frame 
    pp_data <- rbind(...) %>% dplyr::select(Algorithm = rlang::sym(column.algorithm), 
                                            JitterTime = rlang::sym(column.time), 
                                            Time = rlang::sym(column.time), 
                                            Timeout = rlang::sym(column.timeout), 
                                            Infeasible = rlang::sym(column.infeasible), 
                                            Failed = rlang::sym(column.failed)) 

    if (length(levels) > 0) {
        pp_data$Algorithm <- factor(pp_data$Algorithm, levels = levels, ordered = TRUE)
    }

    # Find max time
    min_max_time <- pp_data %>% 
        dplyr::filter(!Timeout & !Infeasible & !Failed) %>%
        dplyr::summarize(Max = max(Time), Min = min(Time))
    max_time_log10 <- ceiling(log10(min_max_time$Max))
    min_time_log10 <- 0#floor(log10(min_max_time$Min))
    max_time_exp10 <- 10 ^ max_time_log10
    min_time_exp10 <- 10 ^ min_time_log10

    # Create ticks 
    y_breaks <- 10 ^ seq(min_time_log10, max_time_log10, by = 1)
    if (tex) {
        y_labels <- sapply(y_breaks, \(val) paste0("$10^{", log10(val), "}$"))
    } else {
        y_labels <- sapply(y_breaks, \(val) paste0("10e", log10(val)))
    }
    y_breaks <- c(0, y_breaks)
    if (tex) {
        y_labels <- c("$0$", y_labels) 
    } else {
        y_labels <- c("0", y_labels)
    }

    # Remap infeasible solutions, timeouts and failed runs
    label.infeasible <- label.pdf.infeasible
    label.timeout <- label.pdf.timeout
    label.failed <- label.pdf.failed
    if (tex) {
        label.infeasible <- label.tex.infeasible
        label.timeout <- label.tex.timeout 
        label.failed <- label.tex.failed
    }

    show_infeasible_tick <- show_infeasibles(pp_data, tick.infeasible)
    show_timeout_tick <- show_timeouts(pp_data, tick.timeout)
    show_failed_tick <- show_fails(pp_data, tick.failed)
    show_error_ticks <- show_infeasible_tick || show_timeout_tick || show_failed_tick 

    if (tick.failed == "make_infeasible") {
        pp_data <- pp_data %>% dplyr::mutate(Infeasible = Infeasible | Failed)
    }
     
    offset <- tick.errors.space_below - tick.errors.space_below
    if (show_infeasibles(pp_data, tick.infeasible)) {
        offset <- offset + tick.errors.space_between
        y_breaks <- c(y_breaks, 10 ^ (max_time_log10 + offset))
        y_labels <- c(y_labels, label.infeasible)
    }
    pp_data <- pp_data %>% dplyr::mutate(JitterTime = ifelse(Infeasible & !Timeout, 10 ^ (max_time_log10 + offset), JitterTime),
                                         Time = ifelse(Infeasible & !Timeout, NA, Time))
    if (show_timeouts(pp_data, tick.timeout)) {
        offset <- offset + tick.errors.space_between
        y_breaks <- c(y_breaks, 10 ^ (max_time_log10 + offset))
        y_labels <- c(y_labels, label.timeout)
    }
    pp_data <- pp_data %>% dplyr::mutate(JitterTime = ifelse(Timeout, 10 ^ (max_time_log10 + offset), JitterTime))
    if (show_fails(pp_data, tick.failed)) {
        offset <- offset + tick.errors.space_between
        y_breaks <- c(y_breaks, 10 ^ (max_time_log10 + offset))
        y_labels <- c(y_labels, label.failed)
    }
    pp_data <- pp_data %>% dplyr::mutate(JitterTime = ifelse(Failed & !Timeout & !Infeasible, 10 ^ (max_time_log10 + offset), JitterTime),
                                         Time = ifelse(Failed & !Timeout & !Infeasible, NA, Time))

    stopifnot(nrow(pp_data %>% dplyr::filter(Time == Inf)) == 0)

    jitter_size <- if (tiny) 0.5 else 0.75 

    p <- ggplot(pp_data, aes(x = Algorithm, y = Time)) +
        geom_jitter(aes(y = JitterTime, color = Algorithm, fill = Algorithm), size = jitter_size, alpha = 0.33, pch = 21, width = 0.3) +
        stat_boxplot(aes(color = Algorithm), geom = 'errorbar', width = 0.6) +
        geom_boxplot(aes(color = Algorithm), outlier.shape = NA, alpha = 0.5) +
        scale_y_continuous(trans = "log10", breaks = y_breaks, labels = y_labels, position = position.y) +
        theme_bw()

    if (show_error_ticks) {
        p <- p + geom_hline(yintercept = 10 ^ (max_time_log10 + tick.errors.space_below / 2))
    }

    if (nrow(annotation) > 0) {
        p <- p + geom_text(aes(x = Algorithm, y = 0, label = sprintf("%.1f", Time), vjust = -0.5), annotation, size = 2.5)
    }

    # Set colors
    if (length(colors) > 0) {
        p <- p + 
            scale_color_manual(name = "Algorithm", values = colors) +
            scale_fill_manual(name = "Algorithm", values = colors)
    }

    return (p)
}

