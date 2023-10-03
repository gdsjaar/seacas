# @HEADER
# ************************************************************************
#
#            Trilinos: An Object-Oriented Solver Framework
#                 Copyright (2001) Sandia Corporation
#
#
# Copyright (2001) Sandia Corporation. Under the terms of Contract
# DE-AC04-94AL85000, there is a non-exclusive license for use of this
# work by or on behalf of the U.S. Government.  Export of this program
# may require a license from the United States Government.
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the Corporation nor the names of the
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY SANDIA CORPORATION "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SANDIA CORPORATION OR THE
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# NOTICE:  The United States Government is granted for itself and others
# acting on its behalf a paid-up, nonexclusive, irrevocable worldwide
# license in this data to reproduce, prepare derivative works, and
# perform publicly and display publicly.  Beginning five (5) years from
# July 25, 2001, the United States Government is granted for itself and
# others acting on its behalf a paid-up, nonexclusive, irrevocable
# worldwide license in this data to reproduce, prepare derivative works,
# distribute copies to the public, perform publicly and display
# publicly, and to permit others to do so.
#
# NEITHER THE UNITED STATES GOVERNMENT, NOR THE UNITED STATES DEPARTMENT
# OF ENERGY, NOR SANDIA CORPORATION, NOR ANY OF THEIR EMPLOYEES, MAKES
# ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL LIABILITY OR
# RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY
# INFORMATION, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS
# THAT ITS USE WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
#
# ************************************************************************
# @HEADER


MESSAGE("-- Using FIND_PACKAGE(ADIOS2 ...) ...")

FIND_PACKAGE(ADIOS2)

IF (ADIOS2_FOUND)
    # Tell TriBITS that we found ADIOS2 and there no need to look any further!
    GET_TARGET_PROPERTY(_ADIOS2_INCLUDE_DIRS adios2::adios2 INTERFACE_INCLUDE_DIRECTORIES)
    GET_TARGET_PROPERTY(_ADIOS2_LIBRARY_LOCATION adios2::adios2 LOCATION)
    GET_FILENAME_COMPONENT(ADIOS2_LIBRARY_DIRS ${_ADIOS2_LIBRARY_LOCATION} DIRECTORY)

# For compatibility with TriBITS:
SET(DOCSTR "List of semi-colon separated paths to look for the TPL ADIOS2")

GET_TARGET_PROPERTY(ADIOS2_LOCATION adios2::adios2 LOCATION)

SET(TPL_ADIOS2_LIBRARIES ${ADIOS2_LOCATION} CACHE PATH ${DOCSTR})
SET(TPL_ADIOS2_INCLUDE_DIRS ${_ADIOS2_INCLUDE_DIRS} CACHE PATH ${DOCSTR})
SET(TPL_ADIOS2_LIBRARY_DIRS ${_ADIOS2_LIBRARY_DIRS} CACHE PATH ${DOCSTR})

ENDIF()

#
# Third, call TRIBITS_TPL_FIND_INCLUDE_DIRS_AND_LIBRARIES()
#
TRIBITS_TPL_FIND_INCLUDE_DIRS_AND_LIBRARIES( ADIOS2
  REQUIRED_HEADERS adios2.h
  REQUIRED_LIBS_NAMES adios2_cxx11_mpi,adios2_cxx11,adios2_core_mpi,adios2_core
  )

# NOTE: If FIND_PACKAGE(ADIOS2 ...) was called and successfully found ADIOS2, then
# TRIBITS_TPL_FIND_INCLUDE_DIRS_AND_LIBRARIES() will use the already-set
# variables TPL_ADIOS2_INCLUDE_DIRS and TPL_ADIOS2_LIBRARIES and then print them
# out (and set some other standard variables as well).  This is the final
# "hook" into the TriBITS TPL system.
