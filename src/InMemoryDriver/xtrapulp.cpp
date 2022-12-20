#include <mpi.h>
#include <xtrapulp.h>

#include <chrono>
#include <numeric>

#include "common.h"

using namespace driver;

int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    auto config = parse_arguments(argc, argv);
    auto graph = generate_graph(config);

    auto vtxdist = kagen::BuildVertexDistribution<unsigned long>(
        graph, MPI_UNSIGNED_LONG, MPI_COMM_WORLD);

    const unsigned long n_local =
        graph.vertex_range.second - graph.vertex_range.first;
    const unsigned long n_global = vtxdist.back() - vtxdist.front();
    const unsigned long m_local = graph.edges.size();
    unsigned long m_global;
    MPI_Allreduce(&m_local, &m_global, 1, MPI_UNSIGNED_LONG, MPI_SUM,
                  MPI_COMM_WORLD);

    std::vector<unsigned long> global_ids_vec(n_local);
    std::iota(global_ids_vec.begin(), global_ids_vec.end(),
              graph.vertex_range.first);

    auto [xadj, adjncy, vwgt, ewgt] = kagen::BuildCSR<unsigned long>(std::move(graph));

    unsigned long *const local_adjs = adjncy.data();
    unsigned long *const local_offsets = xadj.data();
    unsigned long *const global_ids = global_ids_vec.data();
    unsigned long *const vert_dist = vtxdist.data();
    const int num_weights = 0;
    int *const vert_weights = nullptr;
    int *const edge_weights = nullptr;

    // Create graph
    dist_graph_t g;
    create_xtrapulp_dist_graph(&g, n_global, m_global, n_local, m_local,
                               local_adjs, local_offsets, global_ids, vert_dist,
                               num_weights, vert_weights, edge_weights);

    pulp_part_control_t ctrl;
    ctrl.vert_balance = 1.03;
    ctrl.edge_balance = 100.0;
    ctrl.constraints = nullptr;
    ctrl.num_weights = 1;
    ctrl.do_maxcut_balance = false;
    ctrl.do_edge_balance = false;
    ctrl.do_bfs_init = false;
    ctrl.do_lp_init = true;
    ctrl.do_repart = false;
    ctrl.verbose_output = true;
    ctrl.pulp_seed = 0;

    std::vector<int> parts(n_local);
    int k = config.k;

    for (int iter = 0; iter < config.repetitions; ++iter) {
        ctrl.pulp_seed = iter;
        xtrapulp_run(&g, &ctrl, parts.data(), k);
    }

    MPI_Finalize();
}
