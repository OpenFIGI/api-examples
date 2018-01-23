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
