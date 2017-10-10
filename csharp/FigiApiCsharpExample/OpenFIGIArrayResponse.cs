using Newtonsoft.Json;
using System.Collections.Generic;

namespace FigiApiCsharpExample
{
    public class OpenFIGIArrayResponse
    {
        [JsonProperty("data")]
        public List<OpenFIGIInstrument> Data { get; set; }

        [JsonProperty("error")]
        public string Error { get; set; }
    }
}
