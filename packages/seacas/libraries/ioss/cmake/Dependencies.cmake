if(CMAKE_PROJECT_NAME STREQUAL "SEACASProj")
TRIBITS_PACKAGE_DEFINE_DEPENDENCIES(
  LIB_OPTIONAL_PACKAGES SEACASExodus Zoltan Kokkos
  LIB_OPTIONAL_TPLS XDMF HDF5 Pamgen CGNS
)
else()
TRIBITS_PACKAGE_DEFINE_DEPENDENCIES(
  LIB_OPTIONAL_PACKAGES SEACASExodus Pamgen Zoltan Kokkos
  LIB_OPTIONAL_TPLS XDMF HDF5 CGNS
)
endif()

