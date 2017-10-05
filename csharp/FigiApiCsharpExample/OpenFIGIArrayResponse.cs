using Newtonsoft.Json;
using System.Collections.Generic;

namespace FigiApiCsharpExample
{
    public class OpenFIGIArrayResponse
    {
        [JsonProperty("data")]
        public List<OpenFIGIInstrument> data { get; set; }
    }
}
