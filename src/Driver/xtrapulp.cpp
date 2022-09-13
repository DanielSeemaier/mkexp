#include <mpi.h>
#include <xtrapulp.h>

#include <chrono>
#include <iostream>
#include <numeric>

#include "common.h"
#include "io.h"

using namespace driver;

int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    auto config = parse_arguments(argc, argv);
    auto graph =
        binary::read<unsigned long>(config.filename, MPI_UNSIGNED_LONG);

    const unsigned long n_local = graph.to - graph.from;
    const unsigned long n_global = graph.vtxdist.back();
    const unsigned long m_local = graph.adjncy.size();
    unsigned long m_global;
    MPI_Allreduce(&m_local, &m_global, 1, MPI_UNSIGNED_LONG, MPI_SUM,
                  MPI_COMM_WORLD);

    std::vector<unsigned long> global_ids_vec(n_local);
    std::iota(global_ids_vec.begin(), global_ids_vec.end(), graph.from);

    unsigned long *const local_adjs = graph.adjncy.data();
    unsigned long *const local_offsets = graph.xadj.data();
    unsigned long *const global_ids = global_ids_vec.data();
    unsigned long *const vert_dist = graph.vtxdist.data();

    std::vector<int> vert_weights_vec(n_local);
    std::fill(vert_weights_vec.begin(), vert_weights_vec.end(), 1);

    const int num_weights = 0;
    int *const vert_weights = nullptr;
    //const int num_weights = 1;
    //int *const vert_weights = vert_weights_vec.data();
    int *const edge_weights = nullptr;

    std::cout << sizeof(unsigned long) << " " << sizeof(unsigned long long)
              << std::endl;
    std::cout << "Read graph with n(global)=" << n_global
              << ", n(local)=" << n_local << ", m(global)=" << m_global
              << ", m(local)=" << m_local << std::endl;

    /*
    std::cout << "graph.from=" << graph.from << ", graph.to=" << graph.to
              << std::endl;
    std::cout << "vtxdist=";
    for (auto &v : graph.vtxdist) {
        std::cout << v << " ";
    }
    std::cout << "\n";
    std::cout << "xadj=";
    for (auto &x : graph.xadj) {
        std::cout << x << " ";
    }
    std::cout << "\n";
    std::cout << "adjncy=";
    for (auto &y : graph.adjncy) {
        std::cout << y << " ";
    }
    std::cout << "\n";
    */

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
