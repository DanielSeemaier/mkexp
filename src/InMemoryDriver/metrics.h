#pragma once

#include <mpi.h>

#include <cmath>
#include <numeric>
#include <vector>

namespace driver {
template <typename BlockID>
double compute_imbalance(const std::vector<BlockID> &partition,
                         const BlockID k) {
    std::vector<unsigned long> block_weights(k);
    for (const auto &block : partition) {
        ++block_weights[block];
    }

    // Compute global block weights
    std::vector<unsigned long> global_block_weights(k);
    MPI_Reduce(block_weights.data(), global_block_weights.data(), k,
               MPI_UNSIGNED_LONG, MPI_SUM, 0, MPI_COMM_WORLD);

    unsigned long global_n = 0;
    unsigned long heaviest_block_weight = 0;
    for (const auto &block_weight : global_block_weights) {
        global_n += block_weight;
        heaviest_block_weight = std::max(block_weight, heaviest_block_weight);
    }

    unsigned long avg_block_weight = std::ceil(1.0 * global_n / k);

    return 1.0 * heaviest_block_weight - avg_block_weight - 1.0;
}
}  // namespace driver
