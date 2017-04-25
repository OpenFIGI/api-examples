import json
import requests
import sys

'''
See https://www.openfigi.com/api for more information.
'''

openfigi_url = 'https://api.openfigi.com/v1/mapping'
openfigi_apikey = ''  # Put API Key here
openfigi_headers = {'Content-Type': 'text/json'}

if openfigi_apikey:
    openfigi_headers['X-OPENFIGI-APIKEY'] = openfigi_apikey

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
    too_many_mapping_jobs = len(jobs) > (100 if openfigi_apikey else 10)
    assert not too_many_mapping_jobs, 'Too many mapping jobs'
    response = requests.post(url=openfigi_url, headers=openfigi_headers,
                             data=json.dumps(jobs))
    if response.status_code != 200:
        print(response.status_code)
        sys.exit(1)
    return response.json()


def pretty_dict(d):
    '''
    Format a dict for `print`ing.

    Parameters
    ----------
    d : dict
        The dict to format

    Returns
    -------
    string
        A "pretty" string represention of `d`.
    '''
    return '|'.join(['%s=%s' % (k, v) for k, v in d.iteritems() if v])


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
        figi_list = [d['figi'] for d in result.get('data', [])]
        result_str = ', '.join(figi_list) or result.get('error')
        output = '%s maps to FIGI(s) ->\n%s\n---' % (pretty_dict(job), result_str)
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
