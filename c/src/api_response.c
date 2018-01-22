#include "api_response.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* parsing */

static void *createAndInitializeArray(size_t n, size_t objSize, void *(*indexer)(void *vec, size_t ix), void (*initializer)(void *)) {
    void *vec = malloc(objSize * n);
    size_t ix;
    if (vec != NULL) {
        for (ix = 0; ix < n; ++ix) {
            initializer(indexer(vec, ix));
        }
    }
    return vec;
}


static void *jobResponseIndexer(void *vec, size_t ix) {
    OpenFIGI_API_JobResponse *ptr = (OpenFIGI_API_JobResponse *) vec;
    return &ptr[ix];
}


static void jobResponseInitializer(void *job_ptr) {
    if (job_ptr == NULL) return;
    OpenFIGI_API_JobResponse *job = (OpenFIGI_API_JobResponse *) job_ptr;
    job->numResults = 0;
    job->results = NULL;
}


static void *resultIndexer(void *vec, size_t ix) {
    OpenFIGI_API_Result *ptr = (OpenFIGI_API_Result *) vec;
    return ptr += ix;
}


static void resultInitializer(void *resultPtr) {
    if (resultPtr == NULL) return;
    OpenFIGI_API_Result *result = (OpenFIGI_API_Result *) resultPtr;
}


static char *copyField(cJSON *json, const char *fieldName, size_t length) {
    cJSON *dataField = cJSON_DetachItemFromObjectCaseSensitive(json, fieldName);
    char *rv = NULL;
    if (dataField != NULL && !cJSON_IsNull(dataField)) {
        rv = (char *) malloc(length);
        strncpy(rv, (const char*) cJSON_GetStringValue(dataField), length);
    }
    cJSON_Delete(dataField);
    return rv;
}


void OpenFIGI_API_printResult(const OpenFIGI_API_Result *result) {
    #define X(name, len) printf("%s: %s\n", #name, result->name != NULL ? result->name : "");
        RESULT_FIELDS
    #undef X
}


static OpenFIGI_API_EC populateResultFromJSON(cJSON *resultJSON, OpenFIGI_API_Result *result) {
    #define X(name, len) result->name = copyField(resultJSON, #name, len);
        RESULT_FIELDS
    #undef X
}


static void deleteIfNotNull(char *ptr) {
    if (ptr != NULL) {
        free(ptr);
    }
}


static void deleteResult(OpenFIGI_API_Result *result) {
    #define X(name, len) deleteIfNotNull(result->name);
        RESULT_FIELDS
    #undef X
}


static OpenFIGI_API_EC populateJobResponseFromJSON(cJSON *json, OpenFIGI_API_JobResponse *response) {
    size_t n;
    size_t objSize = sizeof(OpenFIGI_API_Result);
    cJSON *data = cJSON_GetObjectItemCaseSensitive(json, "data");
    cJSON *res;
    OpenFIGI_API_Result *results, *current;
    if (data == NULL) {
        response->numResults = 0;
        return OpenFIGI_API_SUCCESS;
    }
    n = cJSON_GetArraySize(data);
    results = (OpenFIGI_API_Result *) createAndInitializeArray(n, objSize, resultIndexer, resultInitializer);
    if (results == NULL) {
        response->numResults = -1;
        return OpenFIGI_API_FAILURE;
    }
    current = results;
    cJSON_ArrayForEach(res, data) {
        populateResultFromJSON(res, current);
        current++;
    }
    response->numResults = n;
    response->results = results;
    return OpenFIGI_API_SUCCESS;
}


static OpenFIGI_API_Response createResponseFromJSON(cJSON *jobs) {
    OpenFIGI_API_EC errorCode;
    cJSON *resArray;
    size_t n = cJSON_GetArraySize(jobs);
    size_t objSize = sizeof(OpenFIGI_API_Response);
    OpenFIGI_API_Response response;
    OpenFIGI_API_JobResponse *rv, *current;
    response.numJobs = n;
    response.jobs = NULL;
    if (n > 0) {
        rv = (OpenFIGI_API_JobResponse *) createAndInitializeArray(n, objSize, jobResponseIndexer, jobResponseInitializer);
        if (rv == NULL) {
            response.numJobs = -1;
            return response;
        }
        current = rv;
        cJSON_ArrayForEach(resArray, jobs) {
            errorCode = populateJobResponseFromJSON(resArray, current);
            if (errorCode != OpenFIGI_API_SUCCESS) {
                current->numResults = -1;
            }
            current++;
        }
        response.jobs = rv;
    }
    return response;
}


OpenFIGI_API_Response OpenFIGI_API_SendRequestParsed(const OpenFIGI_API_MappingJob **mappingJobs, size_t numJobs, char *apiKey) {
    char *res;
    cJSON *json;
    OpenFIGI_API_Response response;
    OpenFIGI_API_SendRequest(mappingJobs, numJobs, apiKey, &res);
    json = cJSON_Parse(res);
    response = createResponseFromJSON(json);
    cJSON_Delete(json);
    free(res);
    return response;
}


/* delete objects */


static void deleteJobResponse(OpenFIGI_API_JobResponse *response) {
    size_t i;
    if (response->results == NULL) {
        return;
    }
    for (i = 0; i < response->numResults; ++i) {
        deleteResult(&((response->results)[i]));
    }
    free(response->results);
}


void OpenFIGI_API_DeleteResponse(OpenFIGI_API_Response response) {
    size_t i;
    if (response.jobs == NULL) {
        return;
    }
    for (i = 0; i < response.numJobs; ++i) {

    }
    free(response.jobs);
}
