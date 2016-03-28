# -*- mode: cmake -*-

#
# MSTK NetCDF Find Module
# Shamelessly stolen from Amanzi open source code https://software.lanl.gov/ascem/trac
#
# Usage:
#    Control the search through NetCDF_DIR or setting environment variable
#    NetCDF_ROOT to the NetCDF installation prefix.
#
#    This module does not search default paths! 
#
#    Following variables are set:
#    NetCDF_FOUND            (BOOL)       Flag indicating if NetCDF was found
#    NetCDF_INCLUDE_DIR      (PATH)       Path to the NetCDF include file
#    NetCDF_INCLUDE_DIRS     (LIST)       List of all required include files
#    NetCDF_LIBRARY_DIR      (PATH)       Path to the NetCDF library
#    NetCDF_LIBRARY          (FILE)       NetCDF library
#    NetCDF_LIBRARIES        (LIST)       List of all required NetCDF libraries
#
#    Additional variables set
#    NetCDF_C_LIBRARY        (FILE)       NetCDF C library
#    NetCDF_CXX_LIBRARY      (FILE)       NetCDF C++ library
#    NetCDF_LARGE_DIMS       (BOOL)       Checks the header files for size of 
#                                          NC_MAX_DIMS, NC_MAX_VARS and NC_MAX_VARS_DIMS
#                                          Returns TRUE if
#                                          NC_MAX_DIMS >= 655363
#                                          NC_MAX_VARS >= 524288
#                                          NC_MAX_VAR_DIMS >= 8
#
# #############################################################################

# Standard CMake modules see CMAKE_ROOT/Modules
include(FindPackageHandleStandardArgs)

# MSTK CMake functions see <root>/cmake/modules for source
include(PrintVariable)
include(AddPackageDependency)

if ( NetCDF_LIBRARIES AND NetCDF_INCLUDE_DIRS )

    # Do nothing. Variables are set. No need to search again

else(NetCDF_LIBRARIES AND NetCDF_INCLUDE_DIRS)

    # Cache variables
    if(NetCDF_DIR)
        set(NetCDF_DIR "${NetCDF_DIR}" CACHE PATH "Path to search for NetCDF include and library files")
    endif()

    if(NetCDF_INCLUDE_DIR)
        set(NetCDF_INCLUDE_DIR "${NetCDF_INCLUDE_DIR}" CACHE PATH "Path to search for NetCDF include files")
    endif()

    if(NetCDF_LIBRARY_DIR)
        set(NetCDF_LIBRARY_DIR "${NetCDF_LIBRARY_DIR}" CACHE PATH "Path to search for NetCDF library files")
    endif()

    
    # Search for include files
    # Search order preference:
    #  (1) NetCDF_INCLUDE_DIR - check existence of path AND if the include files exist
    #  (2) NetCDF_DIR/<include>
    #  (3) Default CMake paths See cmake --html-help=out.html file for more information.
    #
    set(netcdf_inc_names "netcdf.h")
    if (NetCDF_INCLUDE_DIR)

        if (EXISTS "${NetCDF_INCLUDE_DIR}")

            find_path(cdf_test_include_path
                      NAMES ${netcdf_inc_names}
                      HINTS ${NetCDF_INCLUDE_DIR}
                      NO_DEFAULT_PATH)
            if(NOT cdf_test_include_path)
                message(SEND_ERROR "Can not locate ${netcdf_inc_names} in ${NetCDF_INCLUDE_DIR}")
            endif()
            set(NetCDF_INCLUDE_DIR "${cdf_test_include_path}")

        else()
            message(SEND_ERROR "NetCDF_INCLUDE_DIR=${NetCDF_INCLUDE_DIR} does not exist")
            set(NetCDF_INCLUDE_DIR "NetCDF_INCLUDE_DIR-NOTFOUND")
        endif()

    else() 

        set(netcdf_inc_suffixes "include")
        if(NetCDF_DIR)

            if (EXISTS "${NetCDF_DIR}" )

                find_path(NetCDF_INCLUDE_DIR
                          NAMES ${netcdf_inc_names}
                          HINTS ${NetCDF_DIR}/include
                          PATH_SUFFIXES ${netcdf_inc_suffixes}
                          NO_DEFAULT_PATH)

            else()
                 message(SEND_ERROR "NetCDF_DIR=${NetCDF_DIR} does not exist")
                 set(NetCDF_INCLUDE_DIR "NetCDF_INCLUDE_DIR-NOTFOUND")
            endif()    


        else()

            find_path(NetCDF_INCLUDE_DIR
                      NAMES ${netcdf_inc_names}
                      PATH_SUFFIXES ${netcdf_inc_suffixes})

        endif()

    endif()


    if ( NOT NetCDF_INCLUDE_DIR )
        message(SEND_ERROR "Can not locate NetCDF include directory")
    endif()

    # Large dimension and parallel check here
    if ( NetCDF_INCLUDE_DIR ) 
       
        set(netcdf_h "${NetCDF_INCLUDE_DIR}/netcdf.h" )
        message(STATUS "NetCDF include file ${netcdf_h} will be searched for define values")

        file(STRINGS "${netcdf_h}" netcdf_max_dims_string REGEX "^#define NC_MAX_DIMS")
        string(REGEX REPLACE "[^0-9]" "" netcdf_max_dims "${netcdf_max_dims_string}")

        file(STRINGS "${netcdf_h}" netcdf_max_vars_string REGEX "^#define NC_MAX_VARS")
        string(REGEX REPLACE "[^0-9]" "" netcdf_max_vars "${netcdf_max_vars_string}")

        file(STRINGS "${netcdf_h}" netcdf_max_var_dims_string REGEX "^#define NC_MAX_VAR_DIMS")
        string(REGEX REPLACE "[^0-9]" "" netcdf_max_var_dims "${netcdf_max_var_dims_string}")

        #PRINT_VARIABLE(netcdf_max_dims_string)
        #PRINT_VARIABLE(netcdf_max_dims)
        #PRINT_VARIABLE(netcdf_max_vars)
        #PRINT_VARIABLE(netcdf_max_var_dims)

        if ( 
             ( (netcdf_max_dims EQUAL 65536)  OR (netcdf_max_dims GREATER 65536) ) AND
             ( (netcdf_max_vars EQUAL 524288) OR (netcdf_max_vars GREATER 524288) )
            )
            set(NetCDF_LARGE_DIMS TRUE)
        else()
            message(WARNING "WARNING: The NetCDF found in ${NetCDF_DIR} does not have the correct NC_MAX_DIMS and NC_MAX_VARS. "
                             "It may not be compatible with Exodus. See NetCDF-Mapping.md for details\n" )
            set(NetCDF_LARGE_DIMS FALSE)
        endif()

	set(NetCDF_PARALLEL False)
        find_path(meta_path
	          NAMES "netcdf_meta.h"
                  HINTS ${NetCDF_INCLUDE_DIR}
                  NO_DEFAULT_PATH)
        if(meta_path)
	   # Search meta for NC_HAS_PARALLEL setting...
	   file(STRINGS "${meta_path}/netcdf_meta.h" netcdf_par_string REGEX "NC_HAS_PARALLEL")
	   string(REGEX REPLACE "[^0-9]" "" netcdf_par_val "${netcdf_par_string}")
	   # NOTE: The line for NC_HAS_PARALLEL has an hdf5 string in it which results
           #       netcdf_par_val being set to 05 or 15 above...
	   if (netcdf_par_val EQUAL 15)
	      set(NetCDF_PARALLEL True)
           endif()    
        endif()

    endif()    

    # Search for libraries 
    # Search order preference:
    #  (1) NetCDF_LIBRARY_DIR - check existence of path AND if the include files exist
    #  (2) NetCDF_DIR/<lib,Lib>
    #  (3) Default CMake paths See cmake --html-help=out.html file for more information.
    #
    if (NetCDF_LIBRARY_DIR)

        if (EXISTS "${NetCDF_LIBRARY_DIR}")

            find_library(NetCDF_C_LIBRARY
                         NAMES netcdf
                         HINTS ${NetCDF_LIBRARY_DIR}
                         NO_DEFAULT_PATH)

#            find_library(NetCDF_CXX_LIBRARY
#                         NAMES netcdf_c++
#                         HINTS ${NetCDF_LIBRARY_DIR}
#                         NO_DEFAULT_PATH)
             
        else()
            message(SEND_ERROR "NetCDF_LIBRARY_DIR=${NetCDF_LIBRARY_DIR} does not exist")
            set(NetCDF_LIBRARY "NetCDF_C_LIBRARY-NOTFOUND")
#            set(NetCDF_LIBRARY "NetCDF_CXX_LIBRARY-NOTFOUND")
        endif()

    else() 

        if(NetCDF_DIR)

            if (EXISTS "${NetCDF_DIR}" )

                find_library(NetCDF_C_LIBRARY
                             NAMES netcdf
                             HINTS ${NetCDF_DIR}
                             PATH_SUFFIXES "lib" "Lib"
                             NO_DEFAULT_PATH)

#                find_library(NetCDF_CXX_LIBRARY
#                             NAMES netcdf_c++
#                             HINTS ${NetCDF_DIR}
#                             PATH_SUFFIXES "lib" "Lib"
#                             NO_DEFAULT_PATH)

            else()
                 message(SEND_ERROR "NetCDF_DIR=${NetCDF_DIR} does not exist")
                 set(NetCDF_LIBRARY "NetCDF_C_LIBRARY-NOTFOUND")
#                 set(NetCDF_LIBRARY "NetCDF_CXX_LIBRARY-NOTFOUND")
            endif()    


        else()

            find_library(NetCDF_C_LIBRARY
                         NAMES netcdf
                         PATH_SUFFIXES ${netcdf_lib_suffixes})
            
#            find_library(NetCDF_CXX_LIBRARY
#                         NAMES netcdf_c++
#                         PATH_SUFFIXES ${netcdf_lib_suffixes})


        endif()

    endif()

    if ( NOT NetCDF_C_LIBRARY )
        message(SEND_ERROR "Can not locate NetCDF C library")
    endif()    
    
#    if ( NOT NetCDF_CXX_LIBRARY )
#        message(SEND_ERROR "Can not locate NetCDF CXX library")
#    endif()    


   
    # Define the LIBRARIES and INCLUDE_DORS
    set(NetCDF_INCLUDE_DIRS ${NetCDF_INCLUDE_DIR})
    set(NetCDF_LIBRARIES    ${NetCDF_CXX_LIBRARY} ${NetCDF_C_LIBRARY})

    # Need to find the NetCDF config script to check for HDF5
    if ( NetCDF_DIR OR NetCDF_BIN_DIR )
        MESSAGE(STATUS "\tNetCDF_DIR is ${NetCDF_DIR}")
        find_program(netcdf_config nc-config 
                       PATHS ${NetCDF_DIR}/bin ${NetCDF_BIN_DIR}
		       NO_DEFAULT_PATH
		       NO_CMAKE_SYSTEM_PATH
                       DOC "NetCDF configuration script")

        if (netcdf_config)
            message(STATUS "Found NetCDF configuration script: ${netcdf_config}")
            execute_process(COMMAND "${netcdf_config}" "--has-hdf5"
                            RESULT_VARIABLE _ret_code
                            OUTPUT_VARIABLE _stdout
                            ERROR_VARIABLE  _stderr
                           )
            string(REGEX REPLACE "[\n\r ]" "" _hdf5_answer ${_stdout})
            message(STATUS "${netcdf_config} --has-hdf5 returned '${_hdf5_answer}'")
            string(COMPARE EQUAL "${_hdf5_answer}" "yes" _has_hdf5)
            if (${_has_hdf5} ) 
                set(NetCDF_NEEDS_HDF5 True)
            else()
                set(NetCDF_NEEDS_HDF5 False)
            endif()    

            execute_process(COMMAND "${netcdf_config}" "--version"
                            RESULT_VARIABLE _ret_code
                            OUTPUT_VARIABLE _stdout
                            ERROR_VARIABLE  _stderr
                           )
            string(REGEX REPLACE "[\n\r]" "" NetCDF_VERSION ${_stdout})

# If --has-pnetcdf returns true, then add pnetcdf as dependent library.
            execute_process(COMMAND "${netcdf_config}" "--has-pnetcdf"
                            RESULT_VARIABLE _ret_code
                            OUTPUT_VARIABLE _stdout
                            ERROR_VARIABLE  _stderr
                           )
            string(REGEX REPLACE "[\n\r ]" "" _pnetcdf_answer ${_stdout})
            message(STATUS "${netcdf_config} --has-pnetcdf returned '${_pnetcdf_answer}'")
            string(COMPARE EQUAL "${_pnetcdf_answer}" "yes" _has_pnetcdf)
            if (${_has_pnetcdf} ) 
                set(NetCDF_NEEDS_PNetCDF True)
            else()
                set(NetCDF_NEEDS_PNetCDF False)
            endif()    


        endif()
    endif()    

    if(NetCDF_NEEDS_HDF5) 
        message(STATUS "NetCDF requires HDF5")
	if ( NOT TARGET hdf5)
          add_package_dependency(NetCDF DEPENDS_ON HDF5)
	endif()
    else()
        message(STATUS "NetCDF does not require HDF5")
    endif()

    if(NetCDF_NEEDS_PNetCDF) 
        message(STATUS "NetCDF requires PNetCDF")
	if ( NOT TARGET pnetcdf)
          add_package_dependency(NetCDF DEPENDS_ON PNetCDF)
	endif()
    else()
        message(STATUS "NetCDF does not require PNetCDF")
    endif()

endif(NetCDF_LIBRARIES AND NetCDF_INCLUDE_DIRS )    

# Send useful message if everything is found
find_package_handle_standard_args(NetCDF DEFAULT_MSG
                                           NetCDF_LIBRARIES
                                           NetCDF_INCLUDE_DIRS)

# find_package)handle)standard_args should set NetCDF_FOUND but it does not!
if ( NetCDF_LIBRARIES AND NetCDF_INCLUDE_DIRS)
    set(NetCDF_FOUND TRUE)
else()
    set(NetCDF_FOUND FALSE)
endif()

# --- Provide a summary of what the module found
if ( NOT NetCDF_FIND_QUIETLY )

  # Create a not found list

  message(STATUS "NetCDF Version: ${NetCDF_VERSION}")
  message(STATUS "\tNetCDF_NEEDS_HDF5        = ${NetCDF_NEEDS_HDF5}")
  message(STATUS "\tNetCDF_NEEDS_PNetCDF     = ${NetCDF_NEEDS_PNetCDF}")
  message(STATUS "\tNetCDF_PARALLEL          = ${NetCDF_PARALLEL}")
  message(STATUS "\tNetCDF_INCLUDE_DIRS      = ${NetCDF_INCLUDE_DIRS}")
  message(STATUS "\tNetCDF_LIBRARIES         = ${NetCDF_LIBRARIES}")

endif()
# For compatability with TriBITS:
SET(DOCSTR "List of semi-colon separated paths to look for the TPL Netcdf")

set(TPL_Netcdf_Enables_Netcdf4 ${NetCDF_NEEDS_HDF5} CACHE BOOL "True if netcdf enables netcdf-4")
set(TPL_Netcdf_Enables_PNetcdf ${NetCDF_NEEDS_PNetCDF} CACHE BOOL "True if netcdf enables pnetcdf")
set(TPL_Netcdf_PARALLEL ${NetCDF_PARALLEL} CACHE BOOL "True if netcdf compiled with parallel enabled")
set(TPL_Netcdf_LIBRARY_DIRS ${_hdf5_LIBRARY_SEARCH_DIRS} CACHE PATH ${DOCSTR})
set(TPL_Netcdf_LIBRARIES ${NetCDF_LIBRARIES} CACHE PATH ${DOCSTR})
set(TPL_Netcdf_INCLUDE_DIRS ${NetCDF_INCLUDE_DIRS} CACHE PATH ${DOCSTR})
mark_as_advanced(
  NetCDF_INCLUDE_DIR
  NetCDF_INCLUDE_DIRS
  NetCDF_C_LIBRARY
  NetCDF_CXX_LIBRARY
  NetCDF_LIBRARIES
  NetCDF_LIBRARY_DIR
)
