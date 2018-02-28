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
#include "mapping_job.h"

#include <cJSON.h>
#include <curl/curl.h>

#include <stdlib.h>
#include <string.h>


static const char *OPENFIGI_API_URL="https://api.openfigi.com/v1/mapping";


#define X(name) const char *name = #name;
    OPENFIGI_ID_TYPES
#undef X


static const char *idTypeToString(OpenFIGI_API_ID idType) {
    switch(idType) {

    #define X(name) case OpenFIGI_API_##name: return name;
    OPENFIGI_ID_TYPES
    #undef X

    }
}

OpenFIGI_API_MappingJob *OpenFIGI_API_CreateMappingJob(OpenFIGI_API_ID idType, char *idValue) {
    OpenFIGI_API_MappingJob *job = (OpenFIGI_API_MappingJob *)
        malloc(sizeof(OpenFIGI_API_MappingJob));
    if (job == NULL) {
        return NULL;
    }
    job->idType = idType;
    job->idValue = idValue;
    job->exchCode = NULL;
    job->micCode = NULL;
    job->currency = NULL;
    job->marketSecDes = NULL;
    return job;
}


static cJSON *checkRv(void *rv, cJSON *json) {
    if (rv==NULL) {
        cJSON_Delete(json);
        json = NULL;
    }
    return json;
}


static cJSON *mappingJobTocJSON(const OpenFIGI_API_MappingJob *mappingJob) {
    cJSON *rv;
    cJSON *json = cJSON_CreateObject();
    if (json != NULL) {
        rv = cJSON_AddStringToObject(json, "idType", idTypeToString(mappingJob->idType));
        json = checkRv(rv, json);
    }
    if (json != NULL) {
        rv = cJSON_AddStringToObject(json, "idValue", mappingJob->idValue);
        json = checkRv(rv, json);
    }
    if (json != NULL) {
        #define X(a) if(mappingJob->a != NULL) cJSON_AddStringToObject(json, #a, mappingJob->a);
            OPTIONAL_PARAMETERS
        #undef X
    }
    return json;
}


char *OpenFIGI_API_MappingJobToJSON(OpenFIGI_API_MappingJob *mappingJob) {
    cJSON *json = mappingJobTocJSON(mappingJob);
    if (json == NULL) return NULL;
    char *rv = cJSON_PrintUnformatted(json);
    cJSON_Delete(json);
    return rv;
}


void OpenFIGI_API_DeleteMappingJob(OpenFIGI_API_MappingJob *mappingJob) {
    if (mappingJob == NULL) {
        return;
    }
    free(mappingJob);
}


/* Request */


static cJSON *requestTocJSON(const OpenFIGI_API_MappingJob **mappingJobs, size_t numJobs) {
    cJSON *json = cJSON_CreateArray();
    cJSON *job;
    cJSON *rv;
    size_t ix;
    if (mappingJobs == NULL) {
        return json;
    }
    for (ix = 0; ix < numJobs; ++ix) {
        job = mappingJobTocJSON(mappingJobs[ix]);
        json = checkRv(job, json);
        if (json != NULL) {
            cJSON_AddItemToArray(json, job);
        }
    }
    return json;
}


void OpenFIGI_API_PrintMappingJob(const OpenFIGI_API_MappingJob *mappingJob) {
    if (mappingJob == NULL) {
        return;
    }
    printf("id %s = %s", idTypeToString(mappingJob->idType), mappingJob->idValue);
}


char *OpenFIGI_API_RequestToJSON(const OpenFIGI_API_MappingJob **mappingJobs, size_t numJobs) {
    cJSON *json = requestTocJSON(mappingJobs, numJobs);
    if (json == NULL) return NULL;
    char *rv = cJSON_PrintUnformatted(json);
    cJSON_Delete(json);
    return rv;
}


struct MemoryStruct {
    char *memory;
    size_t size;
};


static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct MemoryStruct *mem = (struct MemoryStruct *)userp;

    void *ptr = realloc(mem->memory, mem->size + realsize + 1);
    if(ptr == NULL) {
        return 0;
    }
    mem->memory = (char *) ptr;

    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;

    return realsize;
}


OpenFIGI_API_RC OpenFIGI_API_SendRequest(const OpenFIGI_API_MappingJob **mappingJobs, size_t numJobs, char *apiKey, char **response) {
    char *json = OpenFIGI_API_RequestToJSON(mappingJobs, numJobs);
    CURL *curl = curl_easy_init();
    struct MemoryStruct chunk;
    CURLcode res = OpenFIGI_API_OK;
    long rcode = 0;
    char apiKeyHeader[40];
    *response = NULL;

    /* add headers */
    struct curl_slist *list = NULL;

    list = curl_slist_append(list, "Content-Type: text/json");
    if (apiKey != NULL) {
        strcpy(apiKeyHeader, "X-OPENFIGI-APIKEY: ");
        strcat(apiKeyHeader, apiKey);
        list = curl_slist_append(list, apiKeyHeader);
    }
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
    curl_easy_setopt(curl, CURLOPT_URL, OPENFIGI_API_URL);
    curl_easy_setopt(curl, CURLOPT_POST, 1L);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json);

    /* read response in memory */
    if ((chunk.memory = malloc(1)) == NULL) {
        rcode = OpenFIGI_API_OTHER_ERROR;
    }
    else {
        chunk.size = 0;
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

        res = curl_easy_perform(curl);
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &rcode);

        if (res != CURLE_OK) {
            rcode = OpenFIGI_API_OTHER_ERROR;
        }
        *response = chunk.memory;
    }

    curl_slist_free_all(list);
    curl_easy_cleanup(curl);
    free(json);

    return rcode;
}
