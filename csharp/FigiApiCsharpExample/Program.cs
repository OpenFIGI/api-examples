using RestSharp;
using System;
using System.Collections.Generic;
using System.Linq;

namespace FigiApiCsharpExample
{
    class Program
    {
        static void Main(string[] args)
        {
            var client = new RestClient("https://api.openfigi.com/v1/mapping");
            var request = new RestRequest(Method.POST);
            request.RequestFormat = DataFormat.Json;
            request.AddHeader("X-OPENFIGI-APIKEY", "");
            request.AddHeader("Content-Type", "text/json");
            var list = new List<OpenFIGIRequest>()
            {
                new OpenFIGIRequest("ID_ISIN", "US4592001014"),
                new OpenFIGIRequest("TICKER", "MSFT").WithExchangeCode("US").WithMarketSectorDescription("Equity"),
                new OpenFIGIRequest("ID_BB_GLOBAL", "BBG000BLNNH6")
            };

            request.AddJsonBody(list);

            var response = client.Post<List<OpenFIGIArrayResponse>>(request);

            foreach(var dataInstrument in response.Data)
                if (dataInstrument.Data != null && dataInstrument.Data.Any())
                    foreach(var instrument in dataInstrument.Data)
                        Console.WriteLine(instrument.SecurityDescription);
        }
    }
}
