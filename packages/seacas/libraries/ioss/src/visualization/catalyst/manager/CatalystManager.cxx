// Copyright(C) 1999 - 2010-2017 National Technology &Engineering Solutions
// of Sandia, LLC(NTESS).Under the terms of Contract DE - NA0003525 with
// NTESS, the U.S.Government retains certain rights in this software.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following
// disclaimer in the documentation and / or other materials provided
// with the                                                 distribution.
//
// * Neither the name of NTESS nor the names of its
// contributors may be used to endorse or promote products derived
// from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "CatalystManager.h"
#include "vtkDoubleArray.h"
#include "vtkCPDataDescription.h"
#include "vtkCPInputDataDescription.h"
#include "vtkCPProcessor.h"
#include "vtkCPPythonScriptPipeline.h"
#include "../exodus/CatalystExodusMesh.h"
#include "vtkMultiBlockDataSet.h"
#include "vtkMPIController.h"
#include "vtkProcessModule.h"
#include "vtkFieldData.h"
#include "vtkStringArray.h"
#include "vtkIntArray.h"
#include <sstream>
#include <vtksys/SystemInformation.hxx>

CatalystManager::CatalystManager() {
    this->coProcessor = vtkCPProcessor::New();
    this->coProcessor->Initialize();
}

CatalystManager::~CatalystManager() {

}

CatalystExodusMeshBase* CatalystManager::CreateNewPipeline(
                         const char *catalyst_python_filename,
                         const char *catalyst_sierra_block_json,
                         const char *catalyst_sierra_separator_character,
                         const char *catalyst_sierra_input_deck_name, int UnderscoreVectors,
                         int ApplyDisplacements, const char *restart_tag, int enable_logging,
                         int debug_level, const char *results_output_filename,
                         const char *              catalyst_output_directory,
                         std::vector<std::string> &catalyst_sierra_data)
  {
    CatalystExodusMesh* cem = nullptr;

    if (enable_logging) {
      TimerPair       tp = std::make_pair(clock(), clock());
      vtkDoubleArray *da = vtkDoubleArray::New();
      da->SetNumberOfComponents(3);
      LoggingPair lp                         = std::make_pair(tp, da);
      this->logging[results_output_filename] = lp;

      vtkProcessModule *pm   = vtkProcessModule::GetProcessModule();
      vtkMPIController *mpic = vtkMPIController::SafeDownCast(pm->GetGlobalController());
      std::string       s(results_output_filename);
      if (mpic && mpic->GetNumberOfProcesses() > 1) {
        if (mpic->GetLocalProcessId() == 0) {
          ofstream logfile;
          logfile.open((s + ".catalyst.log").c_str(), ios::out | ios::trunc);
          logfile << "# ELAPSED TIME (S)"
                  << ",PROC MEM USED - MIN (KiB)"
                  << ",PROC MEM USED - MAX (KiB)"
                  << ",PROC MEM USED - AVG (KiB)"
                  << ",HOST MEM USED - MIN (KiB)"
                  << ",HOST MEM USED - MAX (KiB)"
                  << ",HOST MEM USED - AVG (KiB)"
                  << ",TIME SINCE LAST LOG - MIN (S)"
                  << ",TIME SINCE LAST LOG - MAX (S)"
                  << ",TIME SINCE LAST LOG - AVG (S)"
                  << "\n";
          logfile.close();
        }
      }
      else {
        ofstream logfile;
        logfile.open((s + ".catalyst.log").c_str(), ios::out | ios::trunc);
        logfile << "# ELAPSED TIME (S)"
                << ",PROC MEM USED (KiB)"
                << ",HOST MEM USED (KiB)"
                << ",TIME SINCE LAST LOG (S)"
                << "\n";
        logfile.close();
      } 
    }

    if (this->pipelines.find(results_output_filename) == this->pipelines.end()) {
      vtkCPDataDescription *     dd = vtkCPDataDescription::New();
      vtkCPPythonScriptPipeline *pl = vtkCPPythonScriptPipeline::New();

      cem = new CatalystExodusMesh(this);
      cem->SetCatalystPipelineName(results_output_filename);
      cem->SetUnderscoreVectors(UnderscoreVectors);
      cem->SetApplyDisplacements(ApplyDisplacements);

      dd->AddInput("input");
      dd->GetInputDescriptionByName("input")->SetGrid(
          cem->getMultiBlockDataSet());

      PipelineDataDescPair pddp                = std::make_pair(pl, dd);
      this->pipelines[results_output_filename] = pddp;
    }

    if (catalyst_sierra_block_json) {
      vtkFieldData *  fd = vtkFieldData::New();
      vtkStringArray *sa = vtkStringArray::New();
      sa->SetName("catalyst_sierra_data");
      vtkIntArray *ec = vtkIntArray::New();
      ec->SetName("catalyst_sierra_error_codes");
      vtkStringArray *em = vtkStringArray::New();
      em->SetName("catalyst_sierra_error_messages");
      sa->InsertNextValue(catalyst_sierra_block_json);
      sa->InsertNextValue(catalyst_sierra_separator_character);
      sa->InsertNextValue(catalyst_sierra_input_deck_name);
      sa->InsertNextValue(restart_tag);
      if (enable_logging) {
        sa->InsertNextValue("True");
      }
      else {
        sa->InsertNextValue("");
      }
      std::stringstream ss;
      ss << debug_level;
      sa->InsertNextValue(ss.str().c_str());
      ss.clear();
      sa->InsertNextValue(results_output_filename);
      sa->InsertNextValue(catalyst_output_directory);

      for (int i = 0; i < catalyst_sierra_data.size(); i++)
        sa->InsertNextValue(catalyst_sierra_data[i]);

      fd->AddArray(sa);
      fd->AddArray(ec);
      fd->AddArray(em);
      this->pipelines[results_output_filename].second->SetUserData(fd);
      fd->Delete();
      sa->Delete();
      ec->Delete();
      em->Delete();
    }

    if (this->pipelines[results_output_filename].first->Initialize(catalyst_python_filename) == 0) {
      std::cerr << "Unable to initialize ParaView Catalyst with python script "
                << catalyst_python_filename << std::endl;
      std::cerr << "ParaView Catalyst CoProcessing will not be available." << std::endl;
      this->coProcessor->Delete();
      this->coProcessor = 0;
    }
    return (CatalystExodusMeshBase*) cem;
  }

void CatalystManager::DeletePipeline(const char *results_output_filename) {
    if (this->pipelines.find(results_output_filename) != this->pipelines.end()) {
      this->pipelines[results_output_filename].first->Delete();
      this->pipelines[results_output_filename].second->Delete();
      this->pipelines.erase(results_output_filename);
    }

    if (this->logging.find(results_output_filename) != this->logging.end()) {
      this->logging[results_output_filename].second->Delete();
      this->logging.erase(results_output_filename);
    }
}

void CatalystManager::PerformCoProcessing(const char *results_output_filename,
                                          std::vector<int> & error_and_warning_codes,
                                          std::vector<std::string> & error_and_warning_messages) {
    if (!this->coProcessor)
      return;

    if (this->pipelines.find(results_output_filename) != this->pipelines.end()) {
      error_and_warning_codes.clear();
      error_and_warning_messages.clear();

      vtkCPPythonScriptPipeline *pl = this->pipelines[results_output_filename].first;
      vtkCPDataDescription *dd = this->pipelines[results_output_filename].second;
      pl->Register(0);
      this->coProcessor->AddPipeline(pl);
      this->coProcessor->CoProcess(dd);

      vtkFieldData *fd = this->pipelines[results_output_filename].second->GetUserData();
      vtkIntArray * ec =
          vtkIntArray::SafeDownCast(fd->GetAbstractArray("catalyst_sierra_error_codes"));
      vtkStringArray *em =
          vtkStringArray::SafeDownCast(fd->GetAbstractArray("catalyst_sierra_error_messages"));

      if (ec && em && ec->GetNumberOfTuples() > 0 && em->GetNumberOfTuples() > 0 &&
          ec->GetNumberOfTuples() == em->GetNumberOfTuples()) {
        for (int i = 0; i < ec->GetNumberOfTuples(); i++) {
          error_and_warning_codes.push_back(ec->GetValue(i));
          error_and_warning_messages.push_back(em->GetValue(i));
        }
        fd->RemoveArray("catalyst_sierra_error_codes");
        fd->RemoveArray("catalyst_sierra_error_messages");
        vtkIntArray *ec = vtkIntArray::New();
        ec->SetName("catalyst_sierra_error_codes");
        vtkStringArray *em = vtkStringArray::New();
        em->SetName("catalyst_sierra_error_messages");
        fd->AddArray(ec);
        fd->AddArray(em);
        ec->Delete();
        em->Delete();
      }

      this->coProcessor->RemoveAllPipelines();
      pl->Delete();
    }
}

void CatalystManager::SetTimeData(double currentTime, int timeStep,
                                  const char *results_output_filename) {
    if (!this->coProcessor)
      return;

    if (this->pipelines.find(results_output_filename) != this->pipelines.end()) {
      this->pipelines[results_output_filename].second->SetTimeData(currentTime, timeStep);
    }
}

void CatalystManager::logMemoryUsageAndTakeTimerReading(
    const char *results_output_filename) {
    if (this->logging.find(results_output_filename) != this->logging.end()) {
      vtksys::SystemInformation sysInfo;
      vtkProcessModule *        pm   = vtkProcessModule::GetProcessModule();
      vtkMPIController *        mpic = vtkMPIController::SafeDownCast(pm->GetGlobalController());
      double                    measurements[3];
      measurements[0]   = sysInfo.GetProcMemoryUsed() * (1.0 / 1024.0); // Store in MB
      measurements[1]   = sysInfo.GetHostMemoryUsed() * (1.0 / 1024.0);
      clock_t last_time = this->logging[results_output_filename].first.second;
      measurements[2]   = double(clock() - last_time) / (double)CLOCKS_PER_SEC;
      this->logging[results_output_filename].first.second = clock();
      this->logging[results_output_filename].second->InsertNextTuple(measurements);
    }
}

void CatalystManager::WriteToLogFile(const char *results_output_filename) {
    if (this->logging.find(results_output_filename) != this->logging.end()) {
      vtkProcessModule *pm      = vtkProcessModule::GetProcessModule();
      vtkMPIController *mpic    = vtkMPIController::SafeDownCast(pm->GetGlobalController());
      vtkDoubleArray *  logData = this->logging[results_output_filename].second;
      std::string       s(results_output_filename);
      clock_t           begin_time = this->logging[results_output_filename].first.first;
      if (mpic && mpic->GetNumberOfProcesses() > 1) {
        vtkDoubleArray *recvBufferMin = vtkDoubleArray::New();
        vtkDoubleArray *recvBufferMax = vtkDoubleArray::New();
        vtkDoubleArray *recvBufferSum = vtkDoubleArray::New();
        if (mpic->GetLocalProcessId() == 0) {
          recvBufferMin->SetNumberOfComponents(3);
          recvBufferMin->SetNumberOfTuples(logData->GetNumberOfTuples());

          recvBufferMax->SetNumberOfComponents(3);
          recvBufferMax->SetNumberOfTuples(logData->GetNumberOfTuples());

          recvBufferSum->SetNumberOfComponents(3);
          recvBufferSum->SetNumberOfTuples(logData->GetNumberOfTuples());
        }

        mpic->Reduce(logData, recvBufferMin, vtkCommunicator::MIN_OP, 0);
        mpic->Reduce(logData, recvBufferMax, vtkCommunicator::MAX_OP, 0);
        mpic->Reduce(logData, recvBufferSum, vtkCommunicator::SUM_OP, 0);

        if (mpic->GetLocalProcessId() == 0) {
          ofstream logfile;
          logfile.open((s + ".catalyst.log").c_str(), ios::out | ios::app);
          for (int i = 0; i < logData->GetNumberOfTuples(); i++) {
            double min[3];
            double max[3];
            double sum[3];
            recvBufferMin->GetTuple(i, min);
            recvBufferMax->GetTuple(i, max);
            recvBufferSum->GetTuple(i, sum);
            logfile << double(clock() - begin_time) / (double)CLOCKS_PER_SEC << "," << min[0] << ","
                    << max[0] << "," << sum[0] / (double)mpic->GetNumberOfProcesses() << ","
                    << min[1] << "," << max[1] << ","
                    << sum[1] / (double)mpic->GetNumberOfProcesses() << "," << min[2] << ","
                    << max[2] << "," << sum[2] / (double)mpic->GetNumberOfProcesses() << "\n";
          }
          logfile.close();
        }
        recvBufferMin->Delete();
        recvBufferMax->Delete();
        recvBufferSum->Delete();
      }
      else {
        ofstream logfile;       
        logfile.open((s + ".catalyst.log").c_str(), ios::out | ios::app);
        for (int i = 0; i < logData->GetNumberOfTuples(); i++) {
          double data[3]; 
          logData->GetTuple(i, data);
          logfile << double(clock() - begin_time) / CLOCKS_PER_SEC << "," << data[0] << ","
                  << data[1] << "," << data[2] << "\n";
        }
        logfile.close();
      }
      logData->SetNumberOfTuples(0);
    }
}

extern "C" {
    CatalystManagerBase* CreateCatalystManagerInstance() {
        CatalystManager* p = new CatalystManager();
        return (CatalystManagerBase*) p;
    }
}
