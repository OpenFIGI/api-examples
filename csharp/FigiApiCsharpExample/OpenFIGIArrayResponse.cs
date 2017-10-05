using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FigiApiCsharpExample
{
    public class OpenFIGIArrayResponse
    {
        [JsonProperty("data")]
        public List<OpenFIGIInstrument> data { get; set; }
    }
}
