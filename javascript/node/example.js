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
'use strict';

/**
 * See https://www.openfigi.com/api for more information on the OpenFIGI API.
 *
 * This script is written to be run by Node.js without any external libraries.
 * For more involved use cases, consider using a package manager and open source
 * packages: https://www.npmjs.com/
 */

var https = require('https'),
    format = require('util').format;

var apiKey = null,
    jobs = [
        { idType: 'ID_ISIN', idValue: 'US4592001014' },
        { idType: 'ID_WERTPAPIER', idValue: '851399', exchCode: 'US' },
        { idType: 'ID_BB_UNIQUE', idValue: 'EQ0010080100001000', currency: 'USD' },
        { idType: 'ID_SEDOL', idValue: '2005973', 'micCode': 'EDGX', currency: 'USD' }
    ];

main();

/**
 * Map the defined `jobs` and handle the results.
 * @return {undefined}
 */
function main () {
    mapJobs(jobs, function (jobResults) {
        jobResultsHandler(jobs, jobResults);
        process.exit(0);
    });
}

/**
 * Handle the `mapJobs` results.  See `mapJobs` definition for more info.
 * @param  {Object[]} jobs       The original list of mapping jobs to perform.
 * @param  {Object[]} jobResults The results of the mapping job.
 * @return {undefined}
 */
function jobResultsHandler (jobs, jobResults) {
    jobResults.forEach(function (result, index) {
        var job = jobs[index],
            jobStr = Object.keys(job)
                .map(function (key) { return job[key]; })
                .join('|'),
            figisStr = (result.data || [])
                .map(function (d) { return d.figi; })
                .join(','),
            resultStr = figisStr || result['error'],
            output = format('%s maps to FIGI(s) ->\n%s\n---', jobStr, resultStr);

        console.log(output);
    });
}

/**
 * Send an collection of mapping jobs to the API in order to obtain the
 * associated FIGI(s).
 * @param  {Object[]}   jobs A list of dicts that conform to the OpenFIGI API
 *                           request structure. See
 *                           https://www.openfigi.com/api#request-format for
 *                           more information. Note rate-limiting requirements
 *                           when considering length of `jobs`.
 * @param  {Function} cb   Handle the job mapping results.  Receives two
 *                         arguments: `jobs` and `jobResults`.  The `jobs`
 *                         argument is the same as this function's `jobs`
 *                         argument.  `jobResults` is an Object[] having one
 *                         item per job in `jobs` and conforms to the OpenFIGI
 *                         API response structure.  See
 *                         https://www.openfigi.com/api#response-fomats for more
 *                         information.
 * @return {undefined}     asynchronous
 */
function mapJobs (jobs, cb) {
    var options = {
            hostname: 'api.openfigi.com',
            path: '/v1/mapping',
            method: 'POST',
            headers: { 'Content-Type': 'text/json' }
        },
        req;

    if (apiKey)
        options.headers['X-OPENFIGI-APIKEY'] = apiKey;

    req = https.request(options, function (res) {
        var data = '';

        res.setEncoding('utf8');

        res.on('data', function (chunk) {
            data += chunk;
        });

        res.on('end', function () {
            cb(JSON.parse(data));
        });
    });

    req.on('error', function (e) {
        console.error(e);
        throw e;
    });

    req.write(JSON.stringify(jobs));
    req.end();
}
