#!/usr/bin/env Rscript
options(show.error.locations = TRUE)
options(error = traceback)

# Install and load required libraries
libs <- c("cli", "ggplot2", "plyr", "dplyr", "tidyr", "RColorBrewer", "gridExtra", "egg")
for (lib in libs) {
    if (!require(lib, character.only = TRUE, warn.conflicts = FALSE, quietly = TRUE)) {
        install.packages(lib, repos = "https://cran.uni-muenster.de/")
    }

    library(lib, character.only = TRUE, quietly = TRUE)
}

# Load plotting functions
initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)

# Load script plots
load_script <- function(name) {
    source(file.path(script.basename, "../plots/", name), chdir = TRUE)
}

load_script("performance_profile_plot.R")
load_script("running_time_box_plot.R")

# Load statistics of known graphs
graphs_db <- read.csv(file.path(script.basename, "../data/graphs.csv"), header = TRUE, sep = ",") |> dplyr::distinct()

# Create directory for the plots
if (!dir.exists("plots")) {
    dir.create("plots")
}

# Read CLI arguments to decide on which algorithms to include and which plots to use
algorithms <- c()
plots <- c()
ignore_balance <- FALSE
filter_eps <- 0.00
filter_k <- 0
filename_suffix <- ""
filter_failed <- FALSE
max_k <- 1000000000

for (arg in commandArgs(trailingOnly = TRUE)) {
    if (!startsWith(arg, "--")) {
        algorithms <- c(algorithms, arg)
    } else if (startsWith(arg, "--graph-suffix")) {
        suffix <- substring(arg, nchar("--graph-suffix=") + 1)
        graphs_db <- graphs_db %>% dplyr::mutate(Graph = paste0(Graph, suffix))
    } else if (arg == "--ignore-imbalance") {
        ignore_balance <- TRUE
    } else if (arg == "--filter-failed") {
        filter_failed <- TRUE
    } else if (startsWith(arg, "--filter-eps")) {
        filter_eps <- substring(arg, nchar("--filter-eps=") + 1)
    } else if (startsWith(arg, "--filter-k")) {
        filter_k <- substring(arg, nchar("--filter-k=") + 1)
    } else if (startsWith(arg, "--max-k=")) {
        max_k <- substring(arg, nchar("--max-k=") + 1)
    } else if (startsWith(arg, "--suffix")) {
        filename_suffix <- substring(arg, nchar("--suffix=") + 1)
    } else {
        plots <- c(plots, arg)
    }
}

cat(paste0("Filter epsilon? ", ifelse(filter_eps == 0.0, "No", paste0("Yes: eps == ", filter_eps)), "\n"))
cat(paste0("Filter k? ", ifelse(filter_k == 0, "No", paste0("Yes: k == ", filter_k)), "\n"))
cat(paste0("Max k? ", ifelse(max_k == Inf, "No", paste0("Yes: k <= ", max_k)), "\n"))
cat(paste0("File suffix: ", filename_suffix, "\n"))
cat("\n")

all_plots <- c(
    "--all-cut", "--all-time", "--pairwise-cut",
    "--per-k-cut", "--per-eps-cut", "--per-graph-type-cut", "--per-instance",
    "--detailed-time",
    "--graph-stats",
    "--cut-stats",
    "--hierarchy"
)

default_plots <- c("--all-cut", "--all-time", "--per-instance")

if (length(algorithms) == 0 || "--help" %in% plots) {
    cat("Usage: mkplots [options...] [plots...] algorithms...\n\n")
    cat("Available options:\n")
    cat("\t--filter-eps=<...>    Only use results with the given epsilon value.\n")
    cat("\t--filter-k=<...>      Only use results with the given number of blocks.\n")
    cat("\t--max-k=<...>         Only keep instances with k <= this parameter.\n")
    cat("\t--filter-failed       Remove instances that failed for some configurations from all data sets.\n")
    cat("\t--ignore-imbalance    Ignore imbalanced partitions and treat them as if they were balanced.\n")
    cat("\t--suffix=<...>        Append this suffix to the filenames of plot files.\n")
    cat("\t--graph-suffix=<...>  Append this suffix to the graph names in data/graphs.csv before merging.\n")
    cat("\n")
    cat(paste0("Available plots:", "\n\t", paste(all_plots, collapse = "\n\t"), "\n\n"))
    cat(paste0("Default plots (if none are specified):", "\n\t", paste(default_plots, collapse = "\n\t"), "\n\n"))
    cat("Example: mkplots --all-cut --per-k-cut Algo1 Algo2\n")
    quit()
}

# If there are no picks for plots, build some default plots ...
if (length(plots) == 0) {
    plots <- default_plots
}

if (length(algorithms) == 0) {
    cat("No algorithms specified.\n")
    cat("Usage: mkplots [plots...] algorithms...\n")
    quit()
}

# Load result file for each algorithm
data <- list()

for (algorithm in algorithms) {
    filename <- paste0("results/", algorithm, ".csv")
    if (!file.exists(filename)) {
        cat("Error: no such file:", filename, "\n")
        quit()
    }

    df <- load_data(algorithm, filename, ignore_balance = ignore_balance) %>%
        dplyr::mutate(Algorithm = paste0(Algorithm, "-", NumThreadsPerMPI)) %>%
        dplyr::filter(as.integer(K) <= as.integer(max_k)) %>%
        dplyr::arrange(Graph, K) %>%
        merge(graphs_db, by = "Graph", all.x = TRUE, suffixes = c(".csv", ""))

    if (filter_eps > 0) {
        df <- df %>% dplyr::filter(Epsilon == filter_eps)
    }
    if (filter_k > 0) {
        df <- df %>% dplyr::filter(K == filter_k)
    }
    if (filter_failed) {
        df <- df %>% dplyr::filter(Failed == 0)
    }

    # Very rough classification as regular / irregular graph
    df <- df %>% dplyr::mutate(GraphType = ifelse(MaxDeg / AvgDeg > 50 | MaxDeg > 2000, "Irregular", "Regular"))

    my_num_threads <- unique(df$NumThreadsPerMPI)
    my_ks <- unique(df$K)
    my_graphs <- unique(df$Graph)
    my_eps <- unique(df$Epsilon)

    cat(paste0("\trows = ", nrow(df), "\n"))
    cat(paste0("\tthreads = { ", paste(my_num_threads, collapse = ", "), " }\n"))
    cat(paste0("\tks = { ", paste(my_ks, collapse = ", "), " }\n"))
    cat(paste0("\teps = { ", paste(my_eps, collapse = ", "), " }\n"))
    cat(paste0("\t#graphs = ", length(my_graphs), "\n"))

    # Split dataset into one algorithm for each thread count
    for (num_threads in unique(df$NumThreadsPerMPI)) {
        thread_df <- df %>% dplyr::filter(NumThreadsPerMPI == num_threads)
        data <- append(data, list(thread_df))
    }
}

cat("\n")
cat("Determining common instances among data sets:\n")
common_ks <- sort(unique(data[[1]]$K))
common_graphs <- unique(data[[1]]$Graph)
common_eps <- unique(data[[1]]$Epsilon)
for (i in 1:length(data)) {
    my_ks <- unique(data[[i]]$K)
    my_graphs <- unique(data[[i]]$Graph)
    my_eps <- unique(data[[i]]$Epsilon)
    common_ks <- intersect(common_ks, my_ks)
    common_graphs <- intersect(common_graphs, my_graphs)
    common_eps <- intersect(common_eps, my_eps)
}

for (i in 1:length(data)) {
    name <- data[[i]]$Algorithm[[1]]
    my_ks <- unique(data[[i]]$K)
    my_graphs <- unique(data[[i]]$Graph)
    my_eps <- unique(data[[i]]$Epsilon)

    common_ks <- intersect(common_ks, my_ks)
    common_graphs <- intersect(common_graphs, my_graphs)
    common_eps <- intersect(common_eps, my_eps)

    cat(paste0(
        "\tAlgorithm ", name, ": ",
        "#graphs = ", length(my_graphs), " (-> ", length(common_graphs), "), ",
        "#ks = ", length(my_ks), " (-> ", length(common_ks), "), ",
        "#eps = ", length(my_eps), " (-> ", length(common_eps), ")",
        "\n"
    ))
}

common_graph_types <- sort(unique(data[[1]]$GraphType))

cat(paste0(
    "Common instances: ",
    "#graphs = ", length(common_graphs), ", ",
    "#ks = ", length(common_ks), ", ",
    "#eps = ", length(common_eps), ", ",
    "#graph types = ", length(common_graph_types),
    "\n"
))
cat(paste0("\tks = { ", paste0(common_ks, collapse = ", "), " }\n"))
cat(paste0("\teps = { ", paste0(common_eps, collapse = ", "), "  }\n"))
cat(paste0("\tgraph types = { ", paste0(common_graph_types, collapse = ", "), " }\n"))
cat("\n")

# Filter for common graphs and Ks
for (i in 1:length(data)) {
    data[[i]] <- data[[i]] %>%
        dplyr::filter(
            Graph %in% common_graphs &
                K %in% common_ks &
                Epsilon %in% common_eps
        ) %>%
        dplyr::arrange(Graph, K)
}

cat("Final data set:\n")
for (i in 1:length(data)) {
    name <- data[[i]]$Algorithm[[1]]
    cat(paste0("\tAlgorithm ", name, ": #rows = ", nrow(data[[i]]), "\n"))
}

cat("\n")

cut_plot_theme <- create_theme() + theme(
    legend.position = "bottom"
)


mkpdf <- function(name) pdf(paste0("plots/", name, filename_suffix, ".pdf"), width = 14)

if ("--cut-stats" %in% plots) {
    for (df in data) {
        cat(paste0("Algorithm ", df$Algorithm[[1]], ": ", gm_mean(df$AvgCut), "\n"))
        cat(paste0("\tk<=128: ", gm_mean(dplyr::filter(df, K <= 128)$AvgCut), "\n"))
        cat(paste0("\tk>128: ", gm_mean(dplyr::filter(df, K > 128)$AvgCut), "\n"))
        for (k in common_ks) {
            cat(paste0("\t\tk=", k, ": ", gm_mean(dplyr::filter(df, K == k)$AvgCut), "\n"))
        }
    }
}

if ("--all-cut" %in% plots) {
    mkpdf("cut")
    plot <- do.call(create_performance_profile, data) +
        theme_bw() +
        cut_plot_theme +
        labs(
            title = "Edge Cut Comparison over All Instances",
            subtitle = paste0("k = { ", paste(common_ks, collapse = ", "), " }"),
            caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks), ", #eps = ", length(common_eps))
        )
    print(plot)

    for (k in common_ks) {
        k_data <- list()
        for (df in data) {
            k_df <- df %>% dplyr::filter(K == k)
            k_data <- append(k_data, list(k_df))
        }

        plot <- do.call(create_performance_profile, k_data) +
            theme_bw() +
            cut_plot_theme +
            labs(
                title = paste0("Edge Cut Comparison for k = ", k),
                caption = paste0("#graphs = ", length(common_graphs), ", #ks = 1, #eps = ", length(common_eps))
            )
        print(plot)
    }
    dev.off()
}

if ("--per-k-cut" %in% plots) {
    mkpdf("per_k_cut")
    for (k in common_ks) {
        k_data <- list()
        for (df in data) {
            k_df <- df %>% dplyr::filter(K == k)
            k_data <- append(k_data, list(k_df))
        }

        plot <- do.call(create_performance_profile, k_data) +
            theme_bw() +
            cut_plot_theme +
            labs(
                title = paste0("Edge Cut Comparison for k = ", k),
                caption = paste0("#graphs = ", length(common_graphs), ", #ks = 1, #eps = ", length(common_eps))
            )
        print(plot)
    }
    dev.off()
}

if ("--per-eps-cut" %in% plots) {
    mkpdf("per_eps_cut")
    for (eps in common_eps) {
        eps_data <- list()
        for (df in data) {
            eps_df <- df %>% dplyr::filter(Epsilon == eps)
            eps_data <- append(eps_data, list(eps_df))
        }

        plot <- do.call(create_performance_profile, eps_data) +
            theme_bw() +
            cut_plot_theme +
            labs(
                title = paste0("Edge Cut Comparison for eps = ", 100.0 * eps, "%"),
                caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks), ", #eps = 1")
            )
        print(plot)
    }
    dev.off()
}

if ("--per-graph-type-cut" %in% plots) {
    mkpdf("per_graph_type_cut")
    for (type in common_graph_types) {
        type_data <- list()
        for (df in data) {
            type_df <- df %>% dplyr::filter(GraphType == type)
            type_data <- append(type_data, list(type_df))
        }

        type_graphs <- unique(type_data[[1]]$Graph)

        plot <- do.call(create_performance_profile, type_data) +
            theme_bw() +
            cut_plot_theme +
            labs(
                title = paste0("Edge Cut Comparison for ", type, " Graphs"),
                caption = paste0("#graphs=", length(type_graphs), ", k={", paste(common_ks, collapse = ","), "}, eps={", paste(common_eps, collapse = ","), "}")
            )
        print(plot)
    }
    dev.off()
}

aggregate_running_times <- function(dfs, column = "AvgTime") {
    times <- data.frame(Algorithm = factor(), Gmean = numeric(), Hmean = numeric(), Mean = numeric())
    for (df in dfs) {
        times <- rbind(times, data.frame(
            Algorithm = df$Algorithm[[1]],
            Gmean = gm_mean(df[[column]]),
            Hmean = hm_mean(df[[column]]),
            Mean = mean(df[[column]])
        ))
    }
    return(times)
}

# Pairwise performance profiles
if ("--pairwise-cut" %in% plots) {
    mkpdf("pairwise_cut")
    for (i in 1:(length(data) - 1)) {
        for (j in (i + 1):length(data)) {
            pp <- create_performance_profile(data[[i]], data[[j]]) +
                theme_bw() +
                create_theme() +
                labs(
                    title = "Pairwise Edge Cut Comparison over All Instances",
                    subtitle = paste0("k = { ", paste(common_ks, collapse = ", "), " }"),
                    caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks))
                )
            print(pp)
        }
    }
    dev.off()
}

make_running_time_plot <- function(data, caption, title, subtitle = "", column = "AvgTime") {
    running_time_plot_theme <- create_theme() + theme(
        legend.position = "none",
        axis.title.x = element_blank(),
    )

    all_running_times <- aggregate_running_times(data, column)
    all_running_times_annotation <- data.frame(
        Algorithm = all_running_times$Algorithm,
        Annotation = sprintf("h=%.3f, g=%.3f, a=%.3f", all_running_times$Hmean, all_running_times$Gmean, all_running_times$Mean)
    )

    plot <- do.call(create_running_time_boxplot, c(data, list(annotation = all_running_times_annotation, column.time = column))) +
        theme_bw() +
        running_time_plot_theme +
        labs(title = title, subtitle = subtitle, caption = caption)
    print(plot)
}

filter_data_by_k <- function(data, k) {
    filtered_data <- list()
    for (df in data) {
        filtered_df <- df %>% dplyr::filter(K == k)
        filtered_data <- append(filtered_data, list(filtered_df))
    }
    return(filtered_data)
}

filter_data_by_graph_type <- function(data, graph_type) {
    filtered_data <- list()
    for (df in data) {
        filtered_df <- df %>% dplyr::filter(GraphType == graph_type)
        filtered_data <- append(filtered_data, list(filtered_df))
    }
    return(filtered_data)
}

if ("--all-time" %in% plots) {
    mkpdf("running_time")

    make_running_time_plot(
        data,
        caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks)),
        title = "Total Running Times over All Instances",
        subtitle = paste0("k = { ", paste(common_ks, collapse = ", "), " }")
    )

    for (k in common_ks) {
        make_running_time_plot(
            filter_data_by_k(data, k),
            caption = paste0("#graphs = ", length(common_graphs), ", #ks = 1"),
            title = paste0("Total Running Times for k = ", k)
        )
    }

    # for (type in common_graph_types) {
    # make_running_time_plot(
    # filter_data_by_graph_type(type),
    # caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks)),
    # title = paste0("Running Times for ", type, " Graphs")
    # )
    # }

    dev.off()
}

if ("--detailed-time" %in% plots) {
    mkpdf("detailed_time")

    # Assume that we have the same columns in all data sets ...
    detailed_time_cols <- c(
        "AvgTimeCoarsening",
        "AvgTimeCoarseningLabelPropagation",
        "AvgTimeCoarseningToplevel",
        "AvgTimeCoarseningToplevelLabelPropagation",
        "AvgTimeCoarseningCoarse",
        "AvgTimeCoarseningCoarseLabelPropagation"
    )
    data_cols <- colnames(data[[1]])

    for (col in detailed_time_cols) {
        if (col %in% data_cols) {
            make_running_time_plot(
                data,
                column = col,
                caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks)),
                title = paste0(col, " over All Instances"),
                subtitle = paste0("k = { ", paste(common_ks, collapse = ", "), " }")
            )
        }
    }
    dev.off()
}

if ("--per-instance" %in% plots) {
    side_len <- round(sqrt(length(common_graphs)))
    relative_to <- data[[1]]

    normalized <- data.frame()
    for (df in data) {
        df$RelAvgTime <- df$AvgTime / relative_to$AvgTime
        df$RelAvgCut <- df$AvgCut / relative_to$AvgCut
        normalized <- rbind(normalized, df)
    }

    normalized <- normalized %>%
        dplyr::mutate(K = factor(K)) %>%
        dplyr::mutate(Title = paste0(Graph, " (", MaxDeg, ")")) %>%
        dplyr::mutate(MaxDegToM = MaxDeg / M)

    normalized$Title <- factor(
        normalized$Title,
        levels = unique(normalized$Title[order(normalized$MaxDeg, decreasing = TRUE)])
    )

    pdf(paste0("plots/per_instance.pdf"), height = 14, width = 21)

    # Cuts
    plot <- ggplot(normalized, aes(x = K, y = RelAvgCut, fill = Algorithm)) +
        geom_bar(
            stat = "identity",
            position = position_dodge()
        ) +
        ylab("Relative Cut") +
        xlab("Number of Blocks") +
        theme_bw() +
        facet_wrap(~Title, ncol = side_len, scales = "free") +
        geom_hline(yintercept = 1) +
        create_theme_facet() +
        theme(
            strip.text = element_text(size = 10),
            legend.position = "bottom"
        ) +
        labs(
            title = "Cuts",
            subtitle = "Per Instance, Relative to the First Algorithm, Lower is Better",
            caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks))
        ) +
        scale_x_discrete(guide = guide_axis(n.dodge = 2))
    print(plot)

    # Running time
    p <- ggplot(normalized, aes(x = K, y = RelAvgTime, fill = Algorithm)) +
        geom_bar(
            stat = "identity",
            position = position_dodge()
        ) +
        ylab("Relative Time") +
        xlab("Number of Blocks") +
        theme_bw() +
        facet_wrap(~Title, ncol = side_len, scales = "free") +
        geom_hline(yintercept = 1) +
        create_theme_facet() +
        theme(
            strip.text = element_text(size = 10),
            legend.position = "bottom",
        ) +
        labs(
            title = "Running Times",
            subtitle = "Per Instance, Relative to the First Algorithm, Lower is Better",
            caption = paste0("#graphs = ", length(common_graphs), ", #ks = ", length(common_ks))
        ) +
        scale_x_discrete(guide = guide_axis(n.dodge = 2))
    print(p)

    dev.off()
}

if ("--ss" %in% plots) {
    pdf("ss.pdf", width = 14, height = 3)
    p <- ggplot(all_data, aes(x = NumPEs, y = AvgTime)) +
        ggtitle("Strong scaling") +
        geom_line() +
        ylab("Running time") +
        xlab("Number of PEs") +
        theme_bw() +
        scale_x_continuous(trans = "log2", breaks = unique(all_data$NumPEs)) +
        facet_wrap(~Graph, ncol = 4, scales = "free") +
        create_theme_facet() +
        theme(legend.position = "right")
    print(p)
    dev.off()
}

if ("--graph-stats" %in% plots) {
    cat("Graphs included in the benchmark set:\n\n")
    graphs <- data[[1]] %>%
        dplyr::distinct(Graph, GraphType, N, M, AvgDeg, MaxDeg)
    print(graphs, width = 120)
    cat("\n")

    regular <- graphs %>% dplyr::filter(GraphType == "Regular")
    irregular <- graphs %>% dplyr::filter(GraphType == "Irregular")

    cat("#graphs:", nrow(graphs), "\n")
    cat("#regular graphs:", nrow(regular), "\n")
    cat("#irregular graphs:", nrow(irregular), "\n")
}

if ("--gain-cache" %in% plots) {
    normalized <- data.frame()

    for (df in data) {
        df <- df %>%
            dplyr::mutate(GCSize = GCSize / data[[1]]$GCSize) %>%
            dplyr::arrange(GCSize) %>%
            dplyr::mutate(X = seq(1, nrow(df)))
        normalized <- rbind(normalized, df)
    }

    mkpdf("gain_cache")
    p <- ggplot(normalized, aes(x = X, y = GCSize, color = Algorithm)) +
        ggtitle("Relative Gain Cache Size") +
        ylab("Relative Gain Cache Size") +
        xlab("Instance") +
        geom_line() +
        geom_point() +
        theme_bw() +
        create_theme() +
        theme(legend.position = "right")
    print(p)
    dev.off()
}

if ("--gain-cache-stats" %in% plots) {
    for (i in 2:length(data)) {
        cat(paste0("Instances with large gain cache for algorithm ", data[[i]]$Algorithm[[1]], ":\n"))
        data[[i]] %>%
            dplyr::mutate(GCSize = GCSize / data[[1]]$GCSize) %>%
            dplyr::filter(GCSize > 0.99) %>%
            dplyr::arrange(GCSize) %>%
            dplyr::select(Graph, GCSize) %>%
            print()
    }
}

if ("--hierarchy" %in% plots) {
    mkpdf("hierarchy")

    flat_data <- do.call(rbind, data)

    theme <- theme_bw() +
        theme(legend.position = "none")

    p_levels <- ggplot(flat_data, aes(x = Algorithm, color = Algorithm, y = AvgLevels)) +
        #geom_jitter(size = 1) +
        stat_boxplot(aes(color = Algorithm), geom = "errorbar", width = 0.6) +
        geom_boxplot(fill = NA, aes(color = Algorithm), outlier.shape = NA, alpha = 0.5) +
        scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
        theme +
        ggtitle("Number of levels in the coarsening hierarchy")
    print(p_levels)

    p_coarse_n_to_fine_n <- ggplot(flat_data, aes(x = Algorithm, color = Algorithm, y = AvgCoarsestN / AvgFinestN)) +
        #geom_jitter(size = 1) +
        stat_boxplot(aes(color = Algorithm), geom = "errorbar", width = 0.6) +
        geom_boxplot(fill = NA, aes(color = Algorithm), outliers = FALSE, outlier.shape = NA, alpha = 0.5) +
        #scale_y_continuous(trans = "log2") +
        scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
        theme +
        ggtitle("n(coarsest) / n(finest), without outliers")
    print(p_coarse_n_to_fine_n)

    p_coarse_m_to_fine_m <- ggplot(flat_data, aes(x = Algorithm, color = Algorithm, y = AvgCoarsestM / AvgFinestM)) +
        #geom_jitter(size = 1) +
        stat_boxplot(aes(color = Algorithm), geom = "errorbar", width = 0.6) +
        geom_boxplot(fill = NA, aes(color = Algorithm), outliers = FALSE, outlier.shape = NA, alpha = 0.5) +
        scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
        theme +
        ggtitle("m(coarsest) / m(finest), without outliers")
    print(p_coarse_m_to_fine_m)

    p_density_increase <- ggplot(flat_data, aes(x = Algorithm, color = Algorithm, y = (AvgCoarsestM / AvgCoarsestN) / (AvgFinestM / AvgFinestN))) +
        stat_boxplot(aes(color = Algorithm), geom = "errorbar", width = 0.6) +
        geom_boxplot(fill = NA, aes(color = Algorithm), outliers = FALSE, outlier.shape = NA, alpha = 0.5) +
        scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
        theme +
        ggtitle("avg_deg(coarsest) / avg_deg(finest)")
    print(p_density_increase)

    dev.off()
}
