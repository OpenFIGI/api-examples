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
#include <stdio.h>
#include <stdlib.h>
#include <cJSON.h>
#include <assert.h>

#include "mapping_job.h"
#include "api_response.h"


int main() {
    const size_t NUM_JOBS = 3;
    size_t i = 0, j = 0;
    char *value = NULL;

    OpenFIGI_API_Response response;
    OpenFIGI_API_JobResponse jobResponse;
    OpenFIGI_API_MappingJob *job;
    OpenFIGI_API_MappingJob *request[NUM_JOBS];
    OpenFIGI_API_RC rc;
    cJSON *parsedResponse, *obj, *obj1;

    job = OpenFIGI_API_CreateMappingJob(OpenFIGI_API_ID_WERTPAPIER, "851399");
    job->exchCode = "US";
    request[0] = job;

    job = OpenFIGI_API_CreateMappingJob(OpenFIGI_API_ID_BB_UNIQUE, "EQ0010080100001000");
    job->currency = "USD";
    request[1] = job;

    job = OpenFIGI_API_CreateMappingJob(OpenFIGI_API_ID_SEDOL, "EQ0010080100001000");
    job->micCode = "EDGX";
    job->currency = "USD";

    request[2] = job;

    response = OpenFIGI_API_SendRequestParsed((const OpenFIGI_API_MappingJob **)request, NUM_JOBS, NULL);

    assert(response.numJobs == NUM_JOBS);

    for (i = 0; i < NUM_JOBS; ++i) {
        jobResponse = response.jobs[i];
        printf("Job %d had %d results \n\n", i, jobResponse.numResults);
        for (j = 0; j < jobResponse.numResults; ++j) {
            OpenFIGI_API_printResult(&jobResponse.results[j]);
            printf("\n");
        }
        printf("\n========\n\n");
    }

    OpenFIGI_API_DeleteResponse(response);

    for (i = 0; i < NUM_JOBS; ++i) {
        OpenFIGI_API_DeleteMappingJob(request[i]);
    }

    return 0;
}
