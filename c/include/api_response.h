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
#ifndef OpenFIGI_API_API_RESPONSE_H
#define OpenFIGI_API_API_RESPONSE_H

#include "enums.h"
#include "mapping_job.h"

#include <cJSON.h>

typedef struct OpenFIGI_API_Result OpenFIGI_API_Result;


#define RESULT_FIELDS\
    X(figi, FIGI_LEN) \
    X(securityType, MAX_FIELD_LEN) \
    X(marketSector, MAX_FIELD_LEN) \
    X(ticker, MAX_FIELD_LEN) \
    X(name, MAX_FIELD_LEN) \
    X(uniqueID, MAX_FIELD_LEN) \
    X(exchCode, EXCH_CODE_LEN) \
    X(shareClass, FIGI_LEN) \
    X(compositeFIGI, FIGI_LEN) \
    X(securityType2, MAX_FIELD_LEN) \
    X(securityDescription, MAX_FIELD_LEN) \
    X(uniqueIDFutOpt, MAX_FIELD_LEN)


struct OpenFIGI_API_Result {
    #define X(name, len) char *name;
        RESULT_FIELDS
    #undef X
};


void OpenFIGI_API_printResult(const OpenFIGI_API_Result *result);

typedef struct OpenFIGI_API_JobResponse OpenFIGI_API_JobResponse;

struct OpenFIGI_API_JobResponse {
    size_t numResults;
    OpenFIGI_API_Result *results;
};

typedef struct OpenFIGI_API_Response {
    size_t numJobs;
    OpenFIGI_API_JobResponse *jobs;
} OpenFIGI_API_Response;

OpenFIGI_API_Response OpenFIGI_API_SendRequestParsed(const OpenFIGI_API_MappingJob **mappingJobs, size_t numJobs, char *apiKey);

void OpenFIGI_API_DeleteResponse(OpenFIGI_API_Response response);

#endif
