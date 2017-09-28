using RestSharp;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
            var list = new List<BloombergRequest>()
            {
                new BloombergRequest("US4592001014"),
                new BloombergRequest("MSFT US Equity"),
                new BloombergRequest("BBG000BLNNH6")
            };

            request.AddJsonBody(list);

            var response = client.Post<List<BloombergArrayResponse>>(request);

            foreach(var dataInstrument in response.Data)
                if (dataInstrument.data != null && dataInstrument.data.Any())
                    foreach(var instrument in dataInstrument.data)
                        Console.WriteLine(instrument.SecurityDescription);
        }
    }
}
