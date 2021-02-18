
#include "CatalystTestFixture.h"
#include "catch.hpp"

TEST_CASE_METHOD(CatalystTestFixture,
    "SimpleBlockCrushTest1", "[exodus to catalyst script]") {
    char *myArgv[4] = {
     "ioss2catalyst",
     "-i",
     "test_data/test1.json",
     "test_data/block_crush_1.e"
    };
    int myArgc = 4;
    runApplicationWithFakeCommandLine(myArgc, myArgv);
    checkTestOutputFileExists("CatalystOutput/test1.0010.png");
}

