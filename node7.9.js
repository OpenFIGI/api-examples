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
    headers = { 'Content-Type': 'text/json' },
    options = {
        hostname: 'api.openfigi.com',
        path: '/v1/mapping',
        method: 'POST',
        headers: headers
    },
    jobs = [
        { idType: 'ID_ISIN', idValue: 'US4592001014' },
        { idType: 'ID_WERTPAPIER', idValue: '851399', exchCode: 'US' },
        { idType: 'ID_BB_UNIQUE', idValue: 'EQ0010080100001000', currency: 'USD' },
        { idType: 'ID_SEDOL', idValue: '2005973', 'micCode': 'EDGX', currency: 'USD' }
    ];

if (apiKey) {
    options.headers['X-OPENFIGI-APIKEY'] = apiKey;
}

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
            figiArr = (result.data || [])
                .map(function (d) {
                    return d.figi;
                }),
            resultStr = figiArr.join(', ') || result['error'],
            output = format('%s maps to FIGI(s) ->\n%s\n---', prettyObj(job), resultStr);

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
    var req = https.request(options, function (res) {
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
        process.exit(1);
    });

    req.write(JSON.stringify(jobs));
    req.end();
}

/**
 * Format an Object for `print`ing.
 * @param  {Object} o The Object to format
 * @return {String}   A "pretty" string represention of `o`.
 */
function prettyObj (o) {
    return Object.keys(o)
        .map(function (key) {
            return format('%s=%s', key, o[key]);
        })
        .join('|');
}
