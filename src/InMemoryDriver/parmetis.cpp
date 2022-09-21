#include <mpi.h>
#include <parmetis.h>

#include <chrono>

#include "common.h"

using namespace driver;

int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    auto config = parse_arguments(argc, argv);
    auto graph = generate_graph(config);
    const std::size_t num_nodes =
        graph.vertex_range.second - graph.vertex_range.first;

    auto vtxdist =
        kagen::BuildVertexDistribution<idx_t>(graph, IDX_T, MPI_COMM_WORLD);
    auto [xadj, adjncy] = kagen::BuildCSR<idx_t>(std::move(graph));

    idx_t k = config.k;
    MPI_Comm comm = MPI_COMM_WORLD;
    std::vector<idx_t> partition(num_nodes);
    double imbalance = 0.03;
    idx_t cut;

    idx_t wgtflag = 0;  // no weights
    idx_t numflag = 0;  // arrays start at 0
    idx_t ncon = 1;

    std::vector<real_t> tpwgts(k);
    for (int i = 0; i < k; ++i) {
        tpwgts[i] = 1.0 / k;
    }
    std::vector<real_t> ubvec(1);
    ubvec[0] = 1.03;

    std::vector<idx_t> options(3);
    options[0] = 1;  // use options
    options[1] = 1;  // show timings

    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    for (int iter = 0; iter < config.repetitions; ++iter) {
        options[2] = iter;  // seed

        MPI_Barrier(MPI_COMM_WORLD);

        auto start = std::chrono::steady_clock::now();
        ParMETIS_V3_PartKway(vtxdist.data(), xadj.data(), adjncy.data(),
                             nullptr, nullptr, &wgtflag, &numflag, &ncon, &k,
                             tpwgts.data(), ubvec.data(), options.data(), &cut,
                             partition.data(), &comm);
        MPI_Barrier(MPI_COMM_WORLD);
        auto end = std::chrono::steady_clock::now();

        const double imbalance = compute_balance<idx_t>(
            num_nodes, k, partition.data());

        if (rank == 0) {
            auto time = std::chrono::duration_cast<std::chrono::milliseconds>(
                            end - start)
                            .count();
            std::cout << "RESULT cut=" << cut << " time=" << 1.0 * time / 1000
                      << " imbalance=" << imbalance << std::endl;
        }
    }

    MPI_Finalize();
}
