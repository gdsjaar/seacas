// Copyright(C) 1999-2010
// Sandia Corporation. Under the terms of Contract
// DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains
// certain rights in this software.
//         
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
// 
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Sandia Corporation nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// -*- Mode: c++ -*-
#ifndef IOSS_Iopx_DatabaseIO_h
#define IOSS_Iopx_DatabaseIO_h

#include <Ioss_DBUsage.h>               // for DatabaseUsage
#include <exodus/Ioex_DatabaseIO.h>     // for DatabaseIO
#include <Ioss_Map.h>                   // for Map
#include <exodusII.h>                   // for ex_entity_type, etc
#include <stddef.h>                     // for size_t
#include <stdint.h>                     // for int64_t
#include <time.h>                       // for nullptr, time_t
#include <functional>                   // for less
#include <map>                          // for map, map<>::value_compare
#include <set>                          // for set
#include <string>                       // for string, operator<
#include <utility>                      // for pair
#include <vector>                       // for vector
#include "Ioss_State.h"                 // for State
#include "mpi.h"                        // for MPI_Comm
namespace Iopx { class DecompositionDataBase; }
namespace Iopx { template <typename INT> class DecompositionData; }

namespace Ioss {
   class EntityBlock;
   class ElementTopology;
   class CommSet;
   class EdgeBlock;
   class EdgeSet;
   class ElementBlock;
   class ElementSet;
   class EntitySet;
   class FaceBlock;
   class FaceSet;
   class Field;
   class GroupingEntity;
   class NodeBlock;
   class NodeSet;
   class PropertyManager;
   class Region;
   class SideBlock;
   class SideSet;
}

namespace Iopx {
  class DatabaseIO : public Ioex::DatabaseIO
  {
  public:
    DatabaseIO(Ioss::Region *region, const std::string& filename,
	       Ioss::DatabaseUsage db_usage, MPI_Comm communicator,
	       const Ioss::PropertyManager &properties);
    ~DatabaseIO();

    bool needs_shared_node_information() const {return true;}
    void compute_node_status() const;
    
    void compute_block_adjacencies() const;

    // Check to see if database state is ok...
    // If 'write_message' true, then output a warning message indicating the problem.
    // If 'error_message' non-null, then put the warning message into the string and return it.
    // If 'bad_count' non-null, it counts the number of processors where the file does not exist.
    //    if ok returns false, but *bad_count==0, then the routine does not support this argument.
    bool ok(bool write_message = false, std::string *error_message=nullptr, int *bad_count=nullptr) const;

    void get_step_times();

    void compute_block_membership(int64_t id, std::vector<std::string> &block_membership) const;

  private:
    int64_t get_field_internal(const Ioss::NodeBlock* nb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::EdgeBlock* nb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::FaceBlock* nb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::ElementBlock* eb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::SideBlock* fb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::NodeSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::EdgeSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::FaceSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::ElementSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::SideSet* fs, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t get_field_internal(const Ioss::CommSet* cs, const Ioss::Field& field,
			   void *data, size_t data_size) const;

    int64_t put_field_internal(const Ioss::NodeBlock* nb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::EdgeBlock* nb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::FaceBlock* nb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::ElementBlock* eb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::SideBlock* fb, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::NodeSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::EdgeSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::FaceSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::ElementSet* ns, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::SideSet* fs, const Ioss::Field& field,
			   void *data, size_t data_size) const;
    int64_t put_field_internal(const Ioss::CommSet* cs, const Ioss::Field& field,
			   void *data, size_t data_size) const;

    int64_t put_Xset_field_internal(ex_entity_type type, const Ioss::EntitySet* ns,
				const Ioss::Field& field, void *data, size_t data_size) const;
    int64_t get_Xset_field_internal(ex_entity_type type, const Ioss::EntitySet* ns,
				const Ioss::Field& field, void *data, size_t data_size) const;

    // Private member functions
    DatabaseIO(const DatabaseIO& from); // do not implement
    DatabaseIO& operator=(const DatabaseIO& from); // do not implement

    int get_file_pointer() const; // Open file and set exodusFilePtr.

    int64_t read_nodal_coordinates();
    void read_elements(const Ioss::ElementBlock& block);

    void create_implicit_global_map() const;
    void output_node_map() const;
    
    // Metadata-related functions.
    void read_meta_data();

    int64_t read_transient_field(ex_entity_type type,
			     const Ioex::VariableNameMap &variables,
			     const Ioss::Field& field,
			     const Ioss::GroupingEntity *ge,
			     void *data) const;

    int64_t read_attribute_field(ex_entity_type type, const Ioss::Field& field,
			     const Ioss::GroupingEntity *ge,
			     void *variables) const;

    int64_t write_attribute_field(ex_entity_type type, const Ioss::Field& field,
			      const Ioss::GroupingEntity *ge,
			      void *variables) const;

    // Handles subsetting of side blocks.
    int64_t read_ss_transient_field(const Ioss::Field& field,
				int64_t id, void *variables,
				std::vector<int> &is_valid_side) const;

    // Should be made more generic again so can rejoin with write_element_transient field
    void write_nodal_transient_field(ex_entity_type type, const Ioss::Field& field,
				     const Ioss::NodeBlock *ge,
				     int64_t count, void *variables) const;
    // Should be made more generic again so can rejoin with write_nodal_transient field
    void write_entity_transient_field(ex_entity_type type, const Ioss::Field& field,
				      const Ioss::GroupingEntity *ge,
				      int64_t count, void *variables) const;
    void write_meta_data();

    // Read related metadata and store it in the region...
    void read_region();
    void get_edgeblocks();
    void get_faceblocks();
    void get_elemblocks();
    void get_blocks(ex_entity_type type, int rank_offset, const std::string &basename);

    void get_sidesets();

    template <typename T> void get_sets(ex_entity_type type, int64_t count, const std::string &base, const T*);
    void get_nodesets();
    void get_edgesets();
    void get_facesets();
    void get_elemsets();

    void get_commsets();

    // ID Mapping functions.
    const Ioss::Map& get_map(ex_entity_type type) const;
    const Ioss::Map& get_map(Ioss::Map &entity_map,
			     int64_t entityCount,
			     int64_t file_offset, int64_t file_count,
			     ex_entity_type entity_type,
			     ex_inquiry inquiry_type) const;

    int64_t node_global_to_local(int64_t global, bool must_exist) const
    {return nodeMap.global_to_local(global, must_exist);}
    
    int64_t element_global_to_local(int64_t global) const
    {return elemMap.global_to_local(global);}

    // Internal data handling
    int64_t handle_node_ids(void* ids, int64_t num_to_get, size_t offset, size_t count) const;
    int64_t handle_element_ids(const Ioss::ElementBlock *eb, void* ids, size_t num_to_get, size_t offset, size_t count) const;
    int64_t handle_face_ids(const Ioss::FaceBlock *eb, void* ids, size_t num_to_get) const;
    int64_t handle_edge_ids(const Ioss::EdgeBlock *eb, void* ids, size_t num_to_get) const;

    int64_t get_side_connectivity(const Ioss::SideBlock* fb, int64_t id, int64_t side_count,
			      void *fconnect, bool map_ids) const;
    int64_t get_side_distributions(const Ioss::SideBlock* fb, int64_t id,
			       int64_t side_count, double *dist_fact, size_t data_size) const;

    int64_t get_side_field(const Ioss::SideBlock* ef_blk,
		       const Ioss::Field& field,
		       void *data, size_t data_size) const;
    int64_t put_side_field(const Ioss::SideBlock* fb,
		       const Ioss::Field& field,
		       void *data, size_t data_size) const;

    // Private member data...
    mutable Iopx::DecompositionDataBase      *decomp;
    mutable Iopx::DecompositionData<int>     *decomp32;
    mutable Iopx::DecompositionData<int64_t> *decomp64;

    mutable Ioss::IntVector   nodeOwningProcessor;   // Processor that owns each node on this processor
    mutable Ioss::Int64Vector nodeGlobalImplicitMap; // Position of this node in the global-implicit ordering
    mutable Ioss::Int64Vector elemGlobalImplicitMap; // Position of this element in the global-implicit ordering

    // Contains the indices of all owned nodes in each nodeset on this processor to pull data
    // from the global list down to the file list.
    // NOTE: Even though map type is GroupingEntity*, it is only valid
    // for a GroupingEntity* which is a NodeSet*
    mutable std::map<const Ioss::GroupingEntity*,Ioss::Int64Vector> nodesetOwnedNodes; 
    
    mutable bool metaDataWritten;
  };
}
#endif
