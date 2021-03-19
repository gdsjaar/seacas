#! /usr/bin/env bash

### The following assumes you are building in a subdirectory of ACCESS Root
if [ "X$ACCESS" == "X" ] ; then
  ACCESS=$(cd ../../..; pwd)
  echo "ACCESS set to ${ACCESS}"
fi
INSTALL_PATH=${INSTALL_PATH:-${ACCESS}}

SHARED="${SHARED:-YES}"
if [[ "$SHARED" == "ON" || "$SHARED" == "YES" ]]
then
  USE_SHARED="1"
else
  USE_SHARED="0"
fi

MPI="${MPI:-NO}"
if [ "$MPI" == "YES" ]
then
  export PARALLEL="--parallel"
  if [ "$CRAY" == "YES" ]
  then
    export CC=cc
  else
    export CC=mpicc
  fi
else
  COMPILER="${COMPILER:-gnu}"
  if [ "$COMPILER" == "gnu" ]
  then
      export CC=gcc
  fi
  if [ "$COMPILER" == "clang" ]
  then
      export CC=clang
  fi
  if [ "$COMPILER" == "intel" ]
  then
      export CC=icc
  fi
  if [ "$COMPILER" == "ibm" ]
  then
      export CC=xlc
  fi
fi

mkdir build
cd build
cmake -DCMAKE_C_COMPILER:FILEPATH=${CC} \
               -DBUILD_SHARED_LIBS:BOOL=${SHARED} \
               -DCMAKE_INSTALL_PREFIX=${INSTALL_PATH} \
               -DCMAKE_BUILD_TYPE=${BUILD_TYPE} ..

cd ..
#make config cc=${CC} prefix=${INSTALL_PATH} shared=${USE_SHARED}

echo ""
echo "         MPI: ${MPI}"
echo "    COMPILER: ${CC}"
echo "      ACCESS: ${ACCESS}"
echo "INSTALL_PATH: ${INSTALL_PATH}"
echo ""
