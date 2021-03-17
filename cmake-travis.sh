#! /usr/bin/env bash

BUILDDIR=${1:-build}
mkdir $BUILDDIR && cd $BUILDDIR

### Set to ON for parallel compile; otherwise OFF for serial (default)
MPI="${MPI:-OFF}"
echo "MPI set to ${MPI}"

### Switch for Debug or Release build:
BUILD_TYPE="${BUILD_TYPE:-RELEASE}"

### The following assumes you are building in a subdirectory of ACCESS Root
### If not, then define "ACCESS" to point to the root of the SEACAS source code.
ACCESS=$(cd ..; pwd)

### If you do not have the X11 developer package on your system
### which provides X11/Xlib.h and the libX11, then change the "ON"
### below to "OFF". It will disable blot and fastq
HAVE_X11=ON

### Set to ON to enable the building of a thread-safe version of the Exodus and IOSS libraries.
THREADSAFE=${THREADSAFE:-OFF}

### The SEACAS code will install in ${INSTALL_PATH}/bin, ${INSTALL_PATH}/lib, and ${INSTALL_PATH}/include.
INSTALL_PATH=${ACCESS}

### TPLs -- 
### Make sure these point to the locations to find the libraries and includes in lib and include
### subdirectories of the specified paths.
### For example, netcdf.h should be in ${NETCDF_PATH}/include
NETCDF_PATH=${ACCESS}
PNETCDF_PATH=${ACCESS}
MATIO_PATH=${ACCESS}
HDF5_PATH=${ACCESS}
CGNS_PATH=${ACCESS}
FAODEL_PATH=${ACCESS}

function check_enable()
{
    local path=$1
    if [ -e "${path}" ]
    then
	echo "ON"
    else
	echo "OFF"
    fi
}

HAVE_NETCDF=$(check_enable "${NETCDF_PATH}/include/netcdf.h")
HAVE_MATIO=$(check_enable "${MATIO_PATH}/include/matio.h")
HAVE_CGNS=$(check_enable "${CGNS_PATH}/include/cgnslib.h")
HAVE_FAODEL=$(check_enable "${FAODEL_PATH}/include/faodel/faodelConfig.h")

### Define to NO to *enable* exodus deprecated functions
OMIT_DEPRECATED_CODE="NO"

### Set to ON to use Kokkos in the Ioss library; otherwise OFF (default)
KOKKOS=${KOKKOS:-OFF}

CUDA_PATH=${CUDA_ROOT} #Set this to the appropriate path

### Set to ON for CUDA compile; otherwise OFF (default) (only used if KOKKOS=ON
CUDA=${CUDA:-OFF}

if [ "${MPI}" == "ON" ]
then
   MPI_EXEC=$(which mpiexec)
   MPI_BIN=$(dirname "${MPI_EXEC}")
   CXX=mpicxx
   CC=mpicc
   FC=mpif77
fi

if [ "$KOKKOS" == "ON" ]
then
  if [ "$CUDA" == "ON" ]
  then
    export "OMPI_CXX=${SEACAS_SRC_DIR}/packages/kokkos/config/nvcc_wrapper"
    export CUDA_MANAGED_FORCE_DEVICE_ALLOC=1
    KOKKOS_SYMBOLS="-D SEACASProj_ENABLE_Kokkos:BOOL=ON \
                    -D TPL_ENABLE_CUDA:Bool=ON \
                    -D CUDA_TOOLKIT_ROOT_DIR:PATH=${CUDA_PATH} \
                    -D Kokkos_ENABLE_Pthread:BOOL=OFF"
  else
    export OMPI_CXX=$(which gcc)
    unset CUDA_MANAGED_FORCE_DEVICE_ALLOC
    KOKKOS_SYMBOLS="-D SEACASProj_ENABLE_Kokkos:BOOL=ON \
                    -D SEACASProj_ENABLE_OpenMP:Bool=ON \
                    -D Kokkos_ENABLE_Pthread:BOOL=OFF"
  fi
else
  KOKKOS_SYMBOLS="-D SEACASProj_ENABLE_Kokkos:BOOL=OFF"
fi

if [ "HAVE_FAODEL" == "ON" ]
then
    DW_SYMBOLS="-DTPL_ENABLE_FAODEL:BOOL=${HAVE_FAODEL} \
                -DFAODEL_LIBRARY_DIRS:PATH=${FAODEL_PATH}/lib \
                -DFAODEL_INCLUDE_DIRS:PATH=${FAODEL_PATH}/include"
fi

rm -f CMakeCache.txt

###------------------------------------------------------------------------
cmake  \
-D CMAKE_CXX_COMPILER:FILEPATH=${CXX} \
-D CMAKE_C_COMPILER:FILEPATH=${CC} \
-D CMAKE_Fortran_COMPILER:FILEPATH=${FC} \
-D CMAKE_CXX_FLAGS="-Wall -Wunused -pedantic" \
-D CMAKE_C_FLAGS="-Wall -Wunused -pedantic" \
-D CMAKE_MACOSX_RPATH:BOOL=ON \
-D CMAKE_INSTALL_RPATH:PATH=${INSTALL_PATH}/lib \
-D BUILD_SHARED_LIBS:BOOL=OFF \
-D CMAKE_BUILD_TYPE=${BUILD_TYPE} \
-D SEACASProj_ENABLE_ALL_PACKAGES:BOOL=ON \
-D SEACASProj_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=ON \
-D SEACASProj_ENABLE_SECONDARY_TESTED_CODE:BOOL=ON \
-D SEACASProj_ENABLE_TESTS=ON \
-D CMAKE_INSTALL_PREFIX:PATH=${INSTALL_PATH} \
-D SEACASProj_SKIP_FORTRANCINTERFACE_VERIFY_TEST:BOOL=ON \
-D SEACASProj_HIDE_DEPRECATED_CODE:BOOL=${OMIT_DEPRECATED_CODE} \
\
-D TPL_ENABLE_Netcdf:BOOL=${HAVE_NETCDF} \
-D TPL_ENABLE_Matio:BOOL=${HAVE_MATIO} \
-D TPL_ENABLE_CGNS:BOOL=${HAVE_CGNS} \
-D TPL_ENABLE_MPI:BOOL=${MPI} \
-D TPL_ENABLE_Pamgen:BOOL=OFF \
-D TPL_ENABLE_Pthread:BOOL=${THREADSAFE} \
-D SEACASExodus_ENABLE_THREADSAFE:BOOL=${THREADSAFE} \
-D SEACASIoss_ENABLE_THREADSAFE:BOOL=${THREADSAFE} \
-D TPL_X11_INCLUDE_DIRS:PATH=/opt/local/include \
-D TPL_ENABLE_X11:BOOL=${HAVE_X11} \
\
${KOKKOS_SYMBOLS} \
${DW_SYMBOLS} \
\
-D MPI_BIN_DIR:PATH=${MPI_BIN} \
-D NetCDF_ROOT:PATH=${NETCDF_PATH} \
-D HDF5_ROOT:PATH=${HDF5_PATH} \
-D HDF5_NO_SYSTEM_PATHS=ON \
-D CGNS_ROOT:PATH=${CGNS_PATH} \
-D Matio_ROOT:PATH=${MATIO_PATH} \
-D PNetCDF_ROOT:PATH=${PNETCDF_PATH} \
\
$EXTRA_ARGS \
..

echo ""
echo "     ACCESS: ${ACCESS}"
echo "         CC: ${CC}"
echo "        CXX: ${CXX}"
echo "         FC: ${FC}"
echo "        MPI: ${MPI}"
echo " THREADSAFE: ${THREADSAFE}"
echo "HAVE_NETCDF: ${HAVE_NETCDF}"
echo " HAVE_MATIO: ${HAVE_MATIO}"
echo "  HAVE_CGNS: ${HAVE_CGNS}"
echo "     KOKKOS: ${KOKKOS}"
echo ""

make -j2

cd ${ACCESS}
