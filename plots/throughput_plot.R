source("texify_graph_names.R")

create_throughput_plot <- function(...,
                                   primary_key = c("Graph", "K"),
                                   column.graph = "Graph",
                                   column.algorithm = "Algorithm",
                                   column.time = "AvgTime",
                                   column.failed = "Failed",
                                   column.infeasible = "Infeasible",
                                   column.timeout = "Timeout",
                                   column.m = "M",
                                   column.num_pes = "NumPEs",
                                   colors = c(),
                                   namer = texify_graph_names_smallk,
                                   tex = FALSE,
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
        stopifnot(column.m %in% colnames(dataset))
        stopifnot(column.algorithm %in% colnames(dataset))
        stopifnot(column.timeout %in% colnames(dataset))
        stopifnot(column.infeasible %in% colnames(dataset))
        stopifnot(column.failed %in% colnames(dataset))
        stopifnot(column.graph %in% colnames(dataset))
        stopifnot(column.num_pes %in% colnames(dataset))

        stopifnot(!(NA %in% dataset[[column.time]]))
        stopifnot(!(NaN %in% dataset[[column.time]]))
        stopifnot(!(-Inf %in% dataset[[column.time]]))
        stopifnot(!(0 %in% dataset[[column.time]]))
        stopifnot(!any(dataset[[column.time]] <= 0))

        stopifnot(nrow(dataset) == nrow(first_dataset))
        stopifnot(dataset[, primary_key] == first_dataset[, primary_key])
        stopifnot(dataset[[column.m]] == first_dataset[[column.m]])
    }

    data <- rbind(...) %>% dplyr::filter(Timeout | !Failed) %>%
                           dplyr::select(Algorithm = rlang::sym(column.algorithm),
                                         Graph = rlang::sym(column.graph),
                                         Time = rlang::sym(column.time),
                                         M = rlang::sym(column.m),
                                         Timeout = rlang::sym(column.timeout),
                                         Infeasible = rlang::sym(column.infeasible),
                                         NumPEs = rlang::sym(column.num_pes))
    data <- data %>% dplyr::mutate(Throughput = M / Time,
                                   Feasibility = ifelse(!Infeasible & !Timeout, 
                                                        "Feasible", 
                                                        ifelse(Timeout, 
                                                               "Timeout", 
                                                               "Infeasible")))
    if (tex) {
        data <- data %>% dplyr::mutate(Graph = namer(Graph))
    }

    # Create power-of-two y labels 
    min_max_throughput <- data %>% dplyr::summarize(Max = max(Throughput), Min = min(Throughput))
    max_log2 <- ceiling(log2(min_max_throughput$Max))
    min_log2 <- floor(log2(min_max_throughput$Min))

    y_breaks <- seq(min_log2, max_log2, by = 2)
    y_labels <- c()
    if (tex) {
        y_labels <- paste0("$2^{", y_breaks, "}$")
    } else {
        y_labels <- paste0("2^", y_breaks)
    }

    p <- ggplot(data, aes(x = NumPEs, y = Throughput, color = Algorithm)) +
        geom_line(aes(linetype = Graph)) +
        geom_point(aes(shape = Feasibility)) +
        xlab("Number of PEs") +
        ylab("Throughput [Edges / s]") +
        scale_y_continuous(trans = "log2", breaks = 2 ^ y_breaks, labels = y_labels) +
        scale_x_continuous(trans = "log2")

    if (length(colors) > 0) {
        p <- p + scale_color_manual(name = "Algorithm", values = colors)
    }

    return(p)
}

