# Copyright(C) 1999-2020, 2024 National Technology & Engineering Solutions
# of Sandia, LLC (NTESS).  Under the terms of Contract DE-NA0003525 with
# NTESS, the U.S. Government retains certain rights in this software.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#
#     * Neither the name of NTESS nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from phactori import *
from paraview.simple import *

#phactori_combine_to_single_python_file_subpiece_begin_1
class PhactoriSliceWithPlaneOperation(PhactoriPlaneOpBase):
  """slice with plane operation, adapter to the catalyst filter

PhactoriSliceWithPlaneOperation is the phactori manager for working with the
ParaView/Catalyst SliceWithPlane() filter and its parameters, providing
access and pipeline/input/output managment via the json, lexx/yacc, or soon
yaml interface. The user may specify a named input to the filter, with the
unnamed default being the incoming data mesh.

For information on the SliceWithPlane() filter from ParaView, see the
ParaView Documentation.

Our experience has been that as of ParaView 5.8 there are some mesh
geometries where the paraview Slice() filter with a plane slice type will
crash while SliceWithPlane() behaves correctly.

The user must define the plane with a point and normal or with three points.
There are defaults which will be used if the user does not supply some or
all of the definition.  PhactoriSliceWithPlaneOperation is a child class of
PhactoriPlaneOpBase, along with PhactoriSliceOperation and
PhactoriClipPlaneOperation. Check the documentation for PhactoriPlaneOpBase
for the many options for defining the plane point(s), including absolute or
relative 3D points, dynamic data-driven point locations, or collocating with
mesh nodes or elements (or offset therefrom).

To add a PhactoriSliceWithPlaneOperation to the incoming script, you add
a sub-block to the "operation blocks" section of the data with the "type"
key given a value of "slicewithplane". One complete but simple example
script:

::

  {
    "camera blocks":{"myslicecam1":{"type":"camera", "look direction":[1.0, 2.0, 3.0]}},
    "representation blocks":{"rep_tmprtr":{"color by scalar":"temperature"}},
    "imageset blocks":{
      "temperature_on_slice_1":{
        "operation":"myslicewithplane1",
        "camera":"myslicecam1",
        "representation":"rep_tmprtr",
        "image basedirectory":"CatalystOutput",
        "image basename":"slice1_temperature."
      }
    },
    "operation blocks":{
      "myslicewithplane1":{
        "type":"slicewithplane",
        "relative point on plane":[0.1, -0.2, 0.3],
        "plane normal":[1.0, 2.0, 3.0]
      }
    }
  }

the plane normal does not need to be a unit vector: Phactori will normalize
it for you (again, see PhactoriClipPlaneOperation)

A minimalist example script using all default behavior will produce 8 images
with autogenerated names with 6 axis aligned views and 2 diagonal xyz views
colored by block index number (cylically).

::

  { "camera blocks":{},
    "representation blocks":{},
    "imageset blocks":{"slice_1_imageset":{"operation":"myslicewithplane1"}},
    "operation blocks":{"myslicewithplane1":{"type":"slicewithplane"}} }

"""

  def CreateParaViewFilter(self, inInputFilter):

    #don't need our own init code at this point, but this is how it would be
    #added
    #def __init__(self):
    #    MySuperClass.__init__(self)

    """create the slice plane filter for ParaView"""
    if PhactoriDbg(100):
      myDebugPrint3('PhactoriSliceWithPlaneOperation.CreateParaViewFilter entered\n', 100)
    #info in block class should already be parsed and checked

    savedActiveSource = GetActiveSource()

    newParaViewFilter = SliceWithPlane(Input=inInputFilter)
    global gParaViewCatalystVersionFlag
    if gParaViewCatalystVersionFlag < 51100:
      newParaViewFilter.Plane = 'Plane'
    else:
      newParaViewFilter.PlaneType = 'Plane'

    self.UpdateSlice(inInputFilter, newParaViewFilter)

    SetActiveSource(newParaViewFilter)
    SetActiveSource(savedActiveSource)

    if PhactoriDbg(100):
      myDebugPrint3('PhactoriSliceWithPlaneOperation.CreateParaViewFilter returning\n', 100)

    return newParaViewFilter

  def DoUpdateDueToChangeInData(self, inIncomingPvFilter,
      outOutgoingPvFilter):
    """the PhactoriSliceWithPlaneOperation may need to update if the point on
       the slice plane was tied to a node, element, or variable min/max
       location"""
    if PhactoriDbg():
      myDebugPrint3("PhactoriSliceWithPlaneOperation::"
          "DoUpdateDueToChangeInData override executing\n")

    if self.MayChangeWithData() == False:
      if PhactoriDbg():
        myDebugPrint3("PhactoriSliceWithPlanePlaneOperation::"
            "DoUpdateDueToChangeInData returning (absolute point or points)\n")
      return

    self.UpdateSlice(inIncomingPvFilter, outOutgoingPvFilter)

    if PhactoriDbg():
      myDebugPrint3("PhactoriSliceWithPlanePlaneOperation::"
          "DoUpdateDueToChangeInData override returning\n")

  def UpdateSlice(self, inIncomingPvFilter, ioOutgoingPvFilter):
    """using the current info on the slice, get all the paraview stuff
       set up correctly"""

    if PhactoriDbg():
      myDebugPrint3("PhactoriSliceWithPlanePlaneOperation::UpdateSlice entered\n")

    originToUse = [0,0,0]
    normalToUse = [0,1,0]
    self.CalculateUpdatedOriginAndNormal(
            inIncomingPvFilter, originToUse, normalToUse)

    if PhactoriDbg():
      myDebugPrint3('  updateslice using normal: ' + \
              str(normalToUse) + '\n')
      myDebugPrint3('  updateslice using origin: ' + str(originToUse) + '\n')
    global gParaViewCatalystVersionFlag
    if gParaViewCatalystVersionFlag < 51100:
      ioOutgoingPvFilter.Plane.Normal = normalToUse
      ioOutgoingPvFilter.Plane.Origin = originToUse
    else:
      ioOutgoingPvFilter.PlaneType.Normal = normalToUse
      ioOutgoingPvFilter.PlaneType.Origin = originToUse

    if PhactoriDbg():
      myDebugPrint3("PhactoriSliceWithPlanePlaneOperation::UpdateSlice returning\n")

#phactori_combine_to_single_python_file_subpiece_end_1
