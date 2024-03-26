// Copyright(C) 1999-2024 National Technology & Engineering Solutions
// of Sandia, LLC (NTESS).  Under the terms of Contract DE-NA0003525 with
// NTESS, the U.S. Government retains certain rights in this software.
//
// See packages/seacas/LICENSE for details

// -*- Mode: c++ -*-
#pragma once

#include "Ioss_DBUsage.h"
#include "Ioss_DatabaseIO.h"
#include "Ioss_Field.h"
#include "Ioss_Map.h"
#include "Ioss_Utils.h"
#include <algorithm>
#include <cstdint>
#include <ctime>
#include <exodusII.h>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "Ioss_CodeTypes.h"
#include "Ioss_DataSize.h"
#include "Ioss_State.h"
#include "ioexnl_export.h"

namespace Ioss {
  class Assembly;
  class Blob;
  class GroupingEntity;
  class Region;
  class EntityBlock;
  class NodeBlock;
  class EdgeBlock;
  class FaceBlock;
  class ElementBlock;
  class EntitySet;
  class NodeSet;
  class EdgeSet;
  class FaceSet;
  class ElementSet;
  class SideBlock;
  class SideSet;
  class StructuredBlock;
  class CommSet;
  class ElementTopology;
  class Field;
  class Map;
  class PropertyManager;
} // namespace Ioss

/** \brief A namespace for the exodus database format.
 */
namespace Ioexnl {
  struct CommunicationMetaData;

  // Used for variable name index mapping
  using VariableNameMap = std::map<std::string, int, std::less<>>;
  using VNMValuePair    = VariableNameMap::value_type;

  // Used to store reduction variables
  using ValueContainer = std::vector<double>;

  // Used for persistent entity IDs
  // The set contains a pair of <ex_entity_type, int>.
  // The ex_entity_type is the exodus entity type defined in
  // exodus's exodusII.h. A couple examples are:
  // EX_ELEM_BLOCK element block and EX_NODE_SET nodeset.
  //
  // The 'int' is the entity id.  The set is used for output databases
  // to ensure that there are no id collisions.
  using EntityIdSet = std::set<std::pair<int64_t, int64_t>>;

  class IOEXNL_EXPORT BaseDatabaseIO : public Ioss::DatabaseIO
  {
  public:
    BaseDatabaseIO(Ioss::Region *region, const std::string &filename, Ioss::DatabaseUsage db_usage,
                   Ioss_MPI_Comm communicator, const Ioss::PropertyManager &props);

    IOSS_NODISCARD std::string get_format() const override { return "ExoNull"; }

    // Check capabilities of input/output database...  Returns an
    // unsigned int with the supported Ioss::EntityTypes or'ed
    // together. If "return_value & Ioss::EntityType" is set, then the
    // database supports that type (e.g. return_value & Ioss::FACESET)
    IOSS_NODISCARD unsigned entity_field_support() const override;

  protected:
    // Check to see if database state is ok...
    // If 'write_message' true, then output a warning message indicating the problem.
    // If 'error_message' non-null, then put the warning message into the string and return it.
    // If 'bad_count' non-null, it counts the number of processors where the file does not exist.
    //    if ok returns false, but *bad_count==0, then the routine does not support this argument.
    IOSS_NODISCARD bool ok_nl(bool write_message = false, std::string *error_message = nullptr,
                              int *bad_count = nullptr) const override;

    IOSS_NODISCARD bool begin_nl(Ioss::State state) override;
    IOSS_NODISCARD bool end_nl(Ioss::State state) override;

    void open_state_file(int state);

    bool begin_state_nl(int state, double time) override;
    bool end_state_nl(int state, double time) override;
    void get_step_times_nl() override = 0;

    IOSS_NODISCARD int maximum_symbol_length() const override { return maximumNameLength; }

    // NOTE: If this is called after write_meta_data, it will have no affect.
    //       Also, it only affects output databases, not input.
    void set_maximum_symbol_length(int requested_symbol_size) override
    {
      if (!is_input()) {
        maximumNameLength = requested_symbol_size;
      }
    }

    size_t handle_block_ids(const Ioss::EntityBlock *eb, ex_entity_type map_type,
                            Ioss::Map &entity_map, void *ids, size_t num_to_get,
                            size_t offset) const;

    void compute_block_membership_nl(Ioss::SideBlock          *efblock,
                                     std::vector<std::string> &block_membership) const override;

    IOSS_NODISCARD int int_byte_size_db() const override;
    void               set_int_byte_size_api(Ioss::DataSize size) const override;

    IOSS_NOOP_GFI(Ioss::Region)
    IOSS_NOOP_GFI(Ioss::NodeBlock)
    IOSS_NOOP_GFI(Ioss::EdgeBlock)
    IOSS_NOOP_GFI(Ioss::FaceBlock)
    IOSS_NOOP_GFI(Ioss::ElementBlock)
    IOSS_NOOP_GFI(Ioss::StructuredBlock)
    IOSS_NOOP_GFI(Ioss::SideBlock)
    IOSS_NOOP_GFI(Ioss::NodeSet)
    IOSS_NOOP_GFI(Ioss::EdgeSet)
    IOSS_NOOP_GFI(Ioss::FaceSet)
    IOSS_NOOP_GFI(Ioss::ElementSet)
    IOSS_NOOP_GFI(Ioss::SideSet)
    IOSS_NOOP_GFI(Ioss::CommSet)
    IOSS_NOOP_GFI(Ioss::Assembly)
    IOSS_NOOP_GFI(Ioss::Blob)

    int64_t put_field_internal(const Ioss::Region *reg, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::NodeBlock *nb, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::EdgeBlock *nb, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::FaceBlock *nb, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::ElementBlock *eb, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::StructuredBlock *sb, const Ioss::Field &field,
                               void *data, size_t data_size) const override = 0;
    int64_t put_field_internal(const Ioss::SideBlock *fb, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::NodeSet *ns, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::EdgeSet *ns, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::FaceSet *ns, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::ElementSet *ns, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::SideSet *fs, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::CommSet *cs, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::Assembly *as, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;
    int64_t put_field_internal(const Ioss::Blob *blob, const Ioss::Field &field, void *data,
                               size_t data_size) const override             = 0;

    virtual void write_meta_data(Ioss::IfDatabaseExistsBehavior behavior) = 0;
    void         write_results_metadata(bool gather_data, Ioss::IfDatabaseExistsBehavior behavior);

    void openDatabase_nl() const override { (void)get_file_pointer(); }

    void closeDatabase_nl() const override
    {
      free_file_pointer();
      close_dw();
    }

    IOSS_NODISCARD int get_file_pointer() const override = 0; // Open file and set exodusFilePtr.

    virtual int free_file_pointer() const; // Close file and set exodusFilePtr.

    virtual bool handle_output_file(bool write_message, std::string *error_msg, int *bad_count,
                                    bool overwrite, bool abort_if_error) const = 0;

    IOSS_NODISCARD int
         get_current_state() const; // Get current state with error checks and usage message.
    void put_qa();
    void put_info();

    template <typename T>
    void internal_gather_results_metadata(ex_entity_type type, std::vector<T *> entities);

    void generate_sideset_truth_table();

    void output_results_names(ex_entity_type type, VariableNameMap &variables,
                              bool reduction) const;
    int  gather_names(VariableNameMap &variables, const Ioss::GroupingEntity *ge, int index,
                      bool reduction);

    void get_nodeblocks();
    void get_assemblies();
    void get_blobs();

    void update_block_omissions_from_assemblies();

    void add_attribute_fields(Ioss::GroupingEntity *block, int attribute_count,
                              const std::string &type);

    void common_write_metadata(Ioss::IfDatabaseExistsBehavior behavior);
    void output_other_meta_data();

    int64_t internal_add_results_fields(ex_entity_type type, Ioss::GroupingEntity *entity,
                                        int64_t position, int64_t block_count,
                                        Ioss::IntVector         &truth_table,
                                        Ioexnl::VariableNameMap &variables);
    int64_t add_results_fields(Ioss::GroupingEntity *entity, int64_t position = 0);
    int64_t add_reduction_results_fields(Ioss::GroupingEntity *entity);
    void    add_mesh_reduction_fields(int64_t id, Ioss::GroupingEntity *entity);

    void add_region_fields();
    void store_reduction_field(const Ioss::Field &field, const Ioss::GroupingEntity *ge,
                               void *variables) const;

    void get_reduction_field(const Ioss::Field &field, const Ioss::GroupingEntity *ge,
                             void *variables) const;
    void write_reduction_fields() const;
    void read_reduction_fields() const;

    // Handle special output time requests -- primarily restart (cycle, keep, overwrite)
    // Given the global region step, return the step on the database...
    IOSS_NODISCARD int get_database_step(int global_step) const;

    void flush_database_nl() const override;
    void finalize_write(int state, double sim_time);

    mutable int m_exodusFilePtr{-1};
    // If using links to file-per-state, the file pointer for "base" file.
    mutable int m_exodusBasePtr{-1};

    mutable std::string m_groupName;

    mutable EntityIdSet ids_;

    mutable int exodusMode{EX_CLOBBER};
    mutable int dbRealWordSize{8};

    mutable int maximumNameLength{32};
    int         spatialDimension{0};

    int64_t edgeCount{0};
    int64_t faceCount{0};

    mutable std::map<ex_entity_type, int> m_groupCount;

    // Communication Set Data
    Ioss::Int64Vector nodeCmapIds;
    Ioss::Int64Vector nodeCmapNodeCnts;
    Ioss::Int64Vector elemCmapIds;
    Ioss::Int64Vector elemCmapElemCnts;
    int64_t           commsetNodeCount{0};
    int64_t           commsetElemCount{0};

    // --- Nodal/Element/Attribute Variable Names -- Maps from sierra
    // field names to index of nodal/element/attribute variable in
    // exodusII. Note that the component suffix of the field is added on
    // prior to searching the map for the index.  For example, given the
    // Sierra field 'displ' which is a VECTOR_3D, the names stored in
    // 'elementMap' would be 'displ_x', 'displ_y' and 'displ_z'.  All
    // names are converted to lowercase.

    mutable std::map<ex_entity_type, Ioss::IntVector> m_truthTable;
    mutable std::map<ex_entity_type, VariableNameMap> m_variables;
    mutable std::map<ex_entity_type, VariableNameMap> m_reductionVariables;

    mutable std::map<ex_entity_type, std::map<int64_t, ValueContainer>> m_reductionValues;

    mutable std::vector<unsigned char> nodeConnectivityStatus;

    // For a database with omitted blocks, this map contains the indices of the
    // active nodes for each nodeset.  If the nodeset is not reduced in size,
    // the map's vector will be empty for that nodeset. If the vector is not
    // empty, then some nodes on that nodeset are only connected to omitted elements.
    mutable std::map<std::string, Ioss::Int64Vector> activeNodeSetNodesIndex;

    time_t timeLastFlush{0};
    int    flushInterval{-1};

    mutable bool fileExists{false}; // False if file has never been opened/created
    mutable bool minimizeOpenFiles{false};

    mutable bool blockAdjacenciesCalculated{false}; // True if the lazy creation of
    // block adjacencies has been calculated.
    mutable bool nodeConnectivityStatusCalculated{
        false}; // True if the lazy creation of
                // nodeConnectivityStatus has been calculated.
  };
} // namespace Ioexnl
