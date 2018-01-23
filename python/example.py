import json
import urllib2

'''
See https://www.openfigi.com/api for more information.
'''

openfigi_apikey = ''  # Put API Key here
jobs = [
    {'idType': 'ID_ISIN', 'idValue': 'US4592001014'},
    {'idType': 'ID_WERTPAPIER', 'idValue': '851399', 'exchCode': 'US'},
    {'idType': 'ID_BB_UNIQUE', 'idValue': 'EQ0010080100001000', 'currency': 'USD'},
    {'idType': 'ID_SEDOL', 'idValue': '2005973', 'micCode': 'EDGX', 'currency': 'USD'}
]


def map_jobs(jobs):
    '''
    Send an collection of mapping jobs to the API in order to obtain the
    associated FIGI(s).

    Parameters
    ----------
    jobs : list(dict)
        A list of dicts that conform to the OpenFIGI API request structure. See
        https://www.openfigi.com/api#request-format for more information. Note
        rate-limiting requirements when considering length of `jobs`.

    Returns
    -------
    list(dict)
        One dict per item in `jobs` list that conform to the OpenFIGI API
        response structure.  See https://www.openfigi.com/api#response-fomats
        for more information.
    '''
    handler = urllib2.HTTPHandler()
    opener = urllib2.build_opener(handler)
    openfigi_url = 'https://api.openfigi.com/v1/mapping'
    request = urllib2.Request(openfigi_url, data=json.dumps(jobs))
    request.add_header('Content-Type','application/json')
    if openfigi_apikey:
        request.add_header('X-OPENFIGI-APIKEY', openfigi_apikey)
    request.get_method = lambda: 'POST'
    connection = opener.open(request)
    if connection.code != 200:
        raise Exception('Bad response code {}'.format(str(response.status_code)))
    return json.loads(connection.read())


def job_results_handler(jobs, job_results):
    '''
    Handle the `map_jobs` results.  See `map_jobs` definition for more info.

    Parameters
    ----------
    jobs : list(dict)
        The original list of mapping jobs to perform.
    job_results : list(dict)
        The results of the mapping job.

    Returns
    -------
        None
    '''
    for job, result in zip(jobs, job_results):
        job_str = '|'.join(job.values())
        figis_str = ','.join([d['figi'] for d in result.get('data', [])])
        result_str = figis_str or result.get('error')
        output = '%s maps to FIGI(s) ->\n%s\n---' % (job_str, result_str)
        print(output)


def main():
    '''
    Map the defined `jobs` and handle the results.

    Returns
    -------
        None
    '''
    job_results = map_jobs(jobs)
    job_results_handler(jobs, job_results)

main()
