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
#ifndef OPENFIGI_API_ENUMS_H
#define OPENFIGI_API_ENUMS_H


#define OPENFIGI_ID_TYPES \
    X(ID_ISIN) \
    X(ID_BB_UNIQUE) \
    X(ID_SEDOL) \
    X(ID_COMMON) \
    X(ID_WERTPAPIER) \
    X(ID_CUSIP) \
    X(ID_CINS) \
    X(ID_BB) \
    X(ID_ITALY) \
    X(ID_EXCH_SYMBOL) \
    X(ID_FULL_EXCHANGE_SYMBOL) \
    X(COMPOSITE_ID_BB_GLOBAL) \
    X(ID_BB_GLOBAL_SHARE_CLASS_LEVEL) \
    X(ID_BB_GLOBAL) \
    X(ID_BB_SEC_NUM_DES) \
    X(TICKER) \
    X(ID_CUSIP_8_CHR) \
    X(OCC_SYMBOL) \
    X(UNIQUE_ID_FUT_OPT) \
    X(OPRA_SYMBOL) \
    X(TRADING_SYSTEM_IDENTIFIER)


#define OPTIONAL_PARAMETERS \
    X(exchCode) \
    X(micCode) \
    X(currency) \
    X(marketSecDes)


typedef enum {
#define X(name) OpenFIGI_API_##name,
    OPENFIGI_ID_TYPES
#undef X
} OpenFIGI_API_ID;


typedef enum {
    OpenFIGI_API_ID_TYPE,
    OpenFIGI_API_ID_VALUE,
    OpenFIGI_API_EXCH_CODE,
    OpenFIGI_API_MIC_CODE,
    OpenFIGI_API_CURRENCY,
    OpenFIGI_API_MARKET_SEC_DES
} OpenFIGI_API_RequestField;


typedef enum {
    OpenFIGI_API_SUCCESS,
    OpenFIGI_API_FAILURE
} OpenFIGI_API_EC;


typedef enum {
    OpenFIGI_API_OK = 200,
    OpenFIGI_API_NOT_ARRAY = 400,
    OpenFIGI_API_INVALID_KEY = 401,
    OpenFIGI_API_INVALID_PATH = 404,
    OpenFIGI_API_INVALID_METHOD = 405,
    OpenFIGI_API_INVALID_CONTENT_TYPE = 406,
    OpenFIGI_API_TOO_MANY_JOBS = 413,
    OpenFIGI_API_TOO_MANY_REQUESTS = 429,
    OpenFIGI_API_SERVER_ERROR = 500,
    OpenFIGI_API_OTHER_ERROR = 999
} OpenFIGI_API_RC;


enum {
    MAX_FIELD_LEN = 45,
    FIGI_LEN = 13,
    EXCH_CODE_LEN = 4
};

#endif
