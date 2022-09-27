#pragma once

#include <kagen.h>
#include <mpi.h>

#include <iostream>
#include <numeric>
#include <string>

namespace driver {
enum class Generator {
    GNM,
    RGG2D,
    RGG3D,
    RDG2D,
    RDG3D,
    BA,
    RHG,
    GRID2D,
    GRID3D,
    KRONECKER,
    RMAT
};

struct Configuration {
    int repetitions;
    int k;
    int eco;
    Generator generator;
    long n, m;
    double radius, gamma, a, b, c, prob;
};

inline Generator get_generator_by_name(const std::string &name) {
    if (name == "gnm") {
        return Generator::GNM;
    } else if (name == "rgg2d") {
        return Generator::RGG2D;
    } else if (name == "rgg3d") {
        return Generator::RGG3D;
    } else if (name == "rdg2d") {
        return Generator::RDG2D;
    } else if (name == "rdg3d") {
        return Generator::RDG3D;
    } else if (name == "ba") {
        return Generator::BA;
    } else if (name == "rhg") {
        return Generator::RHG;
    } else if (name == "grid2d") {
        return Generator::GRID2D;
    } else if (name == "grid3d") {
        return Generator::GRID3D;
    } else if (name == "kronecker") {
        return Generator::KRONECKER;
    } else if (name == "rmat") {
        return Generator::RMAT;
    } else {
        std::cerr << "invalid generator name\n";
        std::exit(1);
    }
}

inline Configuration parse_arguments(int argc, char *argv[]) {
    if (argc < 5) {
        std::cerr << "arguments: <reps> <k> <eco> <generator> ...\n";
        std::exit(1);
    }

    const std::string generator_name = argv[4];

    Configuration config;
    config.generator = get_generator_by_name(generator_name);
    config.repetitions = std::atoi(argv[1]);
    config.k = std::atoi(argv[2]);
    config.eco = std::atoi(argv[3]);
    argc -= 5;
    const int A = 5;

    switch (config.generator) {
        case Generator::GNM:
        case Generator::RGG2D:
        case Generator::RGG3D:
        case Generator::BA:
        case Generator::KRONECKER:
        case Generator::GRID2D:
        case Generator::GRID3D:
            if (argc != 2) {
                std::cerr << "arguments: " << generator_name << " <n> <m>\n";
                std::exit(1);
            }
            config.n = 1ul << std::atol(argv[A]);
            config.m = 1ul << std::atol(argv[A + 1]);
            break;

        case Generator::RDG2D:
        case Generator::RDG3D:
            if (argc != 1) {
                std::cerr << "arguments: " << generator_name << " <m>\n";
                std::exit(1);
            }
            config.m = 1ul << std::atol(argv[A]);
            break;

        case Generator::RHG:
            if (argc != 3) {
                std::cerr << "arguments: " << generator_name
                          << " <gamma> <n> <m>\n";
                std::exit(1);
            }
            config.gamma = std::atof(argv[A]);
            config.n = 1ul << std::atol(argv[A + 1]);
            config.m = 1ul << std::atol(argv[A + 2]);
            break;

        case Generator::RMAT:
            if (argc != 5) {
                std::cerr << "arguments: " << generator_name
                          << " <a> <b> <c> <n> <m>\n";
                std::exit(1);
            }
            config.a = std::atof(argv[A]);
            config.b = std::atof(argv[A + 1]);
            config.c = std::atof(argv[A + 2]);
            config.n = 1ul << std::atol(argv[A + 3]);
            config.m = 1ul << std::atol(argv[A + 4]);
            break;
    }

    return config;
}

inline kagen::KaGenResult generate_graph(const Configuration &config) {
    kagen::KaGen kagen(MPI_COMM_WORLD);
    kagen.EnableOutput(true);

    switch (config.generator) {
        case Generator::GNM:
            return kagen.GenerateUndirectedGNM(config.n, config.m);

        case Generator::RGG2D:
            return kagen.GenerateRGG2D_NM(config.n, config.m);

        case Generator::RGG3D:
            return kagen.GenerateRGG3D_NM(config.n, config.m);

        case Generator::RDG2D:
            return kagen.GenerateRDG2D_M(config.m, false);

        case Generator::RDG3D:
            return kagen.GenerateRDG3D_M(config.m);

        case Generator::BA:
            return kagen.GenerateBA_NM(config.n, config.m);

        case Generator::RHG:
            return kagen.GenerateRHG_NM(config.gamma, config.n, config.m);

        case Generator::GRID2D:
            return kagen.GenerateGrid2D_NM(config.n, config.m);

        case Generator::GRID3D:
            return kagen.GenerateGrid3D_NM(config.n, config.m);

        case Generator::KRONECKER:
            return kagen.GenerateKronecker(config.n, config.m);

        case Generator::RMAT:
            return kagen.GenerateRMAT(config.n, config.m, config.a, config.b,
                                      config.c);
    }

    __builtin_unreachable();
}

template <typename IDX>
double compute_balance(const IDX n, const IDX k, IDX *partition) {
    std::vector<unsigned long long> local_block_sizes(k);
    for (IDX u = 0; u < n; ++u) {
        ++local_block_sizes[partition[u]];
    }

    std::vector<unsigned long long> block_sizes(k);
    MPI_Reduce(local_block_sizes.data(), block_sizes.data(), k, MPI_UNSIGNED_LONG_LONG,
               MPI_SUM, 0, MPI_COMM_WORLD);

    const IDX sum = std::accumulate(block_sizes.begin(), block_sizes.end(), 0ull);
    const double avg_size = 1.0 * sum / k;
    double max_imbalance = 0.0;
    for (IDX b = 0; b < k; ++b) {
        max_imbalance =
            std::max<double>(max_imbalance, block_sizes[b] / avg_size);
    }

    return max_imbalance - 1.0;
}
}  // namespace driver
