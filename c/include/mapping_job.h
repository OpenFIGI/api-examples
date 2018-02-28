/*
Copyright 2017 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
#ifndef OPENFIGI_API_MAPPING_JOB_H
#define OPENFIGI_API_MAPPING_JOB_H

#include "enums.h"

#include <sys/types.h>

typedef struct OpenFIGI_API_MappingJob {
    OpenFIGI_API_ID idType;
    char *idValue;
    char *exchCode;
    char *micCode;
    char *currency;
    char *marketSecDes;
} OpenFIGI_API_MappingJob;

OpenFIGI_API_MappingJob *OpenFIGI_API_CreateMappingJob(OpenFIGI_API_ID idType, char *idValue);

void OpenFIGI_API_PrintMappingJob(const OpenFIGI_API_MappingJob *mappingJob);

char *OpenFIGI_API_MappingJobToJSON(OpenFIGI_API_MappingJob *mappingJob);

void OpenFIGI_API_DeleteMappingJob(OpenFIGI_API_MappingJob *mappingJob);

/* requests */

char *OpenFIGI_API_RequestToJSON(const OpenFIGI_API_MappingJob **mappingJobs, size_t numJobs);

OpenFIGI_API_RC OpenFIGI_API_SendRequest(const OpenFIGI_API_MappingJob **mappingJobs, size_t numJobs, char *apiKey, char **response);

#endif
