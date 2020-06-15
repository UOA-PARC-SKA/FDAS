
#include <iostream>

#include "FDAS.h"
#include "fdas_config.h"

int main(int argc, char **argv) {
    FDAS pipeline(std::cout);
    pipeline.print_configuration();

    pipeline.initialise_accelerator("bin/fdas.aocx", FDAS::chooseFirstPlatform, FDAS::chooseAcceleratorDevices);

    FDAS::FreqDomainType input;
    FDAS::DetectionType output;
    pipeline.run(input, output);

    return 0;
}
