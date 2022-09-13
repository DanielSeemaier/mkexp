#pragma once

#include <mpi.h>

#include <iostream>
#include <string>

namespace driver {
struct Configuration {
    std::string filename;
    int repetitions;
    int k;
};

inline Configuration parse_arguments(int argc, char *argv[]) {
    if (argc < 3) {
        std::cerr << "arguments: <filename> <k> <repetitions>\n";
        std::exit(1);
    }

    Configuration config;
    config.filename = argv[1];
    config.k = std::atoi(argv[2]);
    config.repetitions = std::atoi(argv[3]);

    return config;
}
}  // namespace driver
