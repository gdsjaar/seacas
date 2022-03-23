/*
 * @HEADER
 *
 * ***********************************************************************
 *
 *  Zoltan Toolkit for Load-balancing, Partitioning, Ordering and Coloring
 *                  Copyright 2012 Sandia Corporation
 *
 * Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
 * the U.S. Government retains certain rights in this software.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the Corporation nor the names of the
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY SANDIA CORPORATION "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SANDIA CORPORATION OR THE
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Questions? Contact Karen Devine	kddevin@sandia.gov
 *                    Erik Boman	egboman@sandia.gov
 *
 * ***********************************************************************
 *
 * @HEADER
 */

#ifndef ZOLTAN_PARTITION_TREE_H
#define ZOLTAN_PARTITION_TREE_H

#ifdef __cplusplus
/* if C++, define the rest of this header file as extern C */
extern "C" {
#endif

/*****************************************************************************/
/*
 *  Function to return the partition tree info generated by RCB.
 *  Input:
 *    zz                  --  The Zoltan structure returned by Zoltan_Create.
 *    treeNodeIndex       --  The array index into the tree. Valid indices will
 *                            be from 1 to numParts-1 inclusive. RCB will not
 *                            have a node for terminal nodes. A terminal node
 *                            is indicated by a left_leaf or right_leaf set to
 *                            the negative value of the part ID. A node may be
 *                            connected to both another node (positive) and
 *                            point to a terminal (negative).
 *  Output:
 *    parent              --  parent index number - this will be positive or
 *                            negative based on whether it is the left or right
 *                            leaf and also have an extra +1 applied to the
 *                            magnitude, so to get the treeNodeIndex of the
 *                            parent take the absolute value of parent and do -1.
 *                            The root node will return a parent value of
 *                            -1 or 1 and for zoltan2. That is the only
 *                            case where zoltan2 actually needs the parent value.
 *    left_leaf           --  left leaf index number - Greater than 0 is a
 *                            treeNodeIndex which will start from index 1.
 *                            0 or negative means the negative of a part ID
 *                            so indicates the terminal. The purpose of starting
 *                            at index 1 is so that 0 is not ambiguous between
 *                            describing a node index or a terminal part ID.
 *    right_leaf          --  right leaf index number - See left_leaf for rules.
 *  Returned value:       --  Error code
 */
int Zoltan_RCB_Partition_Tree(
  struct Zoltan_Struct     *zz,
  int    treeNodeIndex,
  int    *parent,
  int    *left_leaf,
  int    *right_leaf
);

/*****************************************************************************/
/*
 *  Function to get the PHG tree size.
 *  Input:
 *    zz                  --  The Zoltan structure returned by Zoltan_Create.
 *  Output:
 *    tree_size           --  will be set to the size of the tree. The tree size
 *                            is the number of pairs of ints in the tree. Each
 *                            pair provides a lo and hi index corresponding to
 *                            the part numbers found below that node. Let N be
 *                            the tree size returned by this function. Then in
 *                            zoltan the phg tree (tree->array) was allocated as
 *                            an array of ints with size N*2. However zoltan phg
 *                            conventions also apply a memory offset of -2 to
 *                            the array ptr so tree->array[0] is not valid
 *                            memory. This means we should request the tree
 *                            elements starting from index 1 in the below method
 *                            Zoltan_PHG_Partition_Tree. The last valid request
 *                            index is N (not N-1). Also note that the phg
 *                            tree can include some 'empty' nodes. These are
 *                            gaps with no data determined by hi_index = -1.
 *                            The purpose of these gaps and the offset of -2
 *                            is to allow an efficient scheme for converting
 *                            from the array index to the parent. See
 *                            Zoltan_PHG_Partition_Tree_Size comments for more
 *                            detail. These conventions were preserved in the
 *                            zoltan2 interface so that Zoltan2_AlgZoltan
 *                            calculates parent indices efficiently. Note that
 *                            the first element (index 1) is always the root.
 *  Returned value:       --  Error code
 */
int Zoltan_PHG_Partition_Tree_Size(
  struct Zoltan_Struct * zz,
  int * tree_size
);

/*****************************************************************************/
/*
 *  Function to access a node of the PHG tree.
 *  Input:
 *    zz                  --  The Zoltan structure returned by Zoltan_Create.
 *    treeNodeIndex       --  The array index into the tree. This should be
 *                            in the inclusive range (1..N) where N is the size
 *                            returned by Zoltan_RCB_Partition_Tree. See the
 *                            above comments for explanation of this +1 offset.
 *  Output:
 *    lo_index            --  lo index of included parts - inclusive. See
 *                            hi_index below for more complete description.
 *    hi_index            --  hi index of included parts - inclusive. Each
 *                            call to Zoltan_PHG_Partition_Tree_Size returns a
 *                            pair (lo_index and hi_index) which is the
 *                            inclusive range of all parts contained under that
 *                            node. This can include terminal nodes in which
 *                            case lo_index = hi_index. The parts will start
 *                            from index 0 and do not have sign conventions so
 *                            they can be interpreted 'naturally'. However
 *                            there is 1 special case since phg can have gaps in
 *                            the tree. These gaps are determined by checking if
 *                            hi_index = -1. The gaps exists because phg is laid
 *                            out in memeory so that there is always a simple
 *                            relationship between the treeNodeIndex and the
 *                            parent index. If treeNodeIndex is even then the
 *                            parent node has index treeNodeIndex/2. If
 *                            treeNodeIndex is odd then the parent index is
 *                            (treeNodeIndex-1)/2. Note that for phg the root
 *                            will always be the first element which is
 *                            treeNodeIndex 1.
 *  Returned value:       --  Error code
 */
int Zoltan_PHG_Partition_Tree(
  struct Zoltan_Struct * zz,
  int    treeNodeIndex,    /* tree node index in zoltan PHG */
  int    *lo_index,       /* low index */
  int    *hi_index       /* high index */
);

#ifdef __cplusplus
} /* closing bracket for extern "C" */
#endif

#endif
