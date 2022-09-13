#pragma once

#include <mpi.h>

#include <fstream>
#include <numeric>
#include <vector>

namespace driver {
template <typename IDX>
struct Graph {
    std::vector<IDX> xadj;
    std::vector<IDX> adjncy;
    std::vector<IDX> vtxdist;
    IDX from;
    IDX to;
};

namespace binary {
template <typename IDX>
std::pair<IDX, IDX> read_header(std::ifstream& in) {
    IDX version, global_n, global_m;
    in.read(reinterpret_cast<char*>(&version), sizeof(IDX));
    in.read(reinterpret_cast<char*>(&global_n), sizeof(IDX));
    in.read(reinterpret_cast<char*>(&global_m), sizeof(IDX));

    return {global_n, global_m};
}

template <typename IDX>
void read_edges(std::ifstream& in, const IDX from, const IDX to,
                std::vector<IDX>& xadj, std::vector<IDX>& adjncy) {
    const IDX n = to - from;
    xadj.resize(n + 1);
    IDX first_edge_index = 0;
    IDX first_invalid_edge_index = 0;

    {
        std::vector<IDX> global_nodes(n + 1);
        const std::streamsize offset = 3 * sizeof(IDX) + from * sizeof(IDX);
        const std::streamsize length = (n + 1) * sizeof(IDX);
        in.seekg(offset);
        in.read(reinterpret_cast<char*>(global_nodes.data()), length);

        first_edge_index = global_nodes.front();
        first_invalid_edge_index = global_nodes.back();

        for (std::size_t i = 0; i < global_nodes.size(); ++i) {
            xadj[i] = static_cast<IDX>((global_nodes[i] - first_edge_index) /
                                       sizeof(IDX));
        };
    }

    // read edges
    adjncy.resize(xadj.back());
    {
        const std::streamsize offset = first_edge_index;
        const std::streamsize length =
            first_invalid_edge_index - first_edge_index;
        in.seekg(offset);
        in.read(reinterpret_cast<char*>(adjncy.data()), length);
    }
}

template <typename IDX>
Graph<IDX> read(const std::string& filename, MPI_Datatype idx_type) {
    std::ifstream in(filename);
    const auto [n_global, m_global] = read_header<IDX>(in);

    int size = 0, rank = 0;
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    const IDX chunk = n_global / size;
    const IDX remainder = n_global % size;
    const IDX from = rank * chunk + std::min<IDX>(rank, remainder);
    const IDX to = std::min<IDX>(
        from + ((rank < remainder) ? chunk + 1 : chunk), n_global);
    const IDX n_local = to - from;

    Graph<IDX> graph;
    graph.from = from;
    graph.to = to;

    read_edges<IDX>(in, from, to, graph.xadj, graph.adjncy);

    graph.vtxdist.resize(size + 1);
    MPI_Allgather(&n_local, 1, idx_type, graph.vtxdist.data() + 1, 1, idx_type,
                  MPI_COMM_WORLD);
    std::partial_sum(graph.vtxdist.begin(), graph.vtxdist.end(),
                     graph.vtxdist.begin());

    return graph;
}
}  // namespace binary
}  // namespace driver
