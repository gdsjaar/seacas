#!/bin/bash
set -e
pwd

echo $HOME
mkdir build
cd build

FORTRAN=NO HAVE_X11=NO NETCDF_PATH=/mingw64 HDF5_PATH=/mingw64 CGNS_PATH=/mingw64 MPI=NO bash ../cmake-config
make -j4
ctest -j 4 --output-on-failure