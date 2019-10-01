if(CMAKE_PROJECT_NAME STREQUAL "SEACASProj")
TRIBITS_PACKAGE_DEFINE_DEPENDENCIES(
  LIB_OPTIONAL_PACKAGES SEACASExodus Zoltan
  LIB_OPTIONAL_TPLS HDF5 Pamgen CGNS ParMETIS Faodel DLlib Pthread ADIOS2 gtest Kokkos DataWarp
)
else()
TRIBITS_PACKAGE_DEFINE_DEPENDENCIES(
  LIB_OPTIONAL_PACKAGES SEACASExodus Pamgen Zoltan Kokkos
  LIB_OPTIONAL_TPLS HDF5 CGNS ParMETIS Faodel DLlib Pthread DataWarp ADIOS2 gtest
)
endif()

TRIBITS_TPL_TENTATIVELY_ENABLE(DLlib)
