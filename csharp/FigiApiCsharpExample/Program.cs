using RestSharp;
using RestSharp.Serializers.NewtonsoftJson;
using System;
using System.Collections.Generic;
using System.Linq;

namespace FigiApiCsharpExample
{
    class Program
    {
        static void Main(string[] args)
        {
            System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls12;
            var client = new RestClient("https://api.openfigi.com/v1/mapping");
            
            var request = new RestRequest("https://api.openfigi.com/v1/mapping", Method.Post);
            request.RequestFormat = DataFormat.Json;
            request.AddHeader("X-OPENFIGI-APIKEY", "");
            request.AddHeader("Content-Type", "text/json");
            var list = new List<OpenFIGIRequest>()
            {
                new OpenFIGIRequest("ID_ISIN", "US4592001014"),
                new OpenFIGIRequest("TICKER", "MSFT").WithExchangeCode("US").WithMarketSectorDescription("Equity"),
                new OpenFIGIRequest("ID_BB_GLOBAL", "BBG000BLNNH6")
            };

            request.RequestFormat = DataFormat.Json;

            client.UseNewtonsoftJson();
            request.AddJsonBody(list);

            var response = client.Post<List<OpenFIGIArrayResponse>>(request);

            foreach(var dataInstrument in response)
            {
                if (dataInstrument.Data != null && dataInstrument.Data.Any())
                {
                    foreach (var instrument in dataInstrument.Data)
                    {
                        Console.WriteLine(instrument.SecurityDescription);
                    }
                }
                else if (dataInstrument.Error != null)
                {
                    Console.WriteLine(dataInstrument.Error);
                }
            }
        }
    }
}
