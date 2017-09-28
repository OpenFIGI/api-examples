using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FigiApiCsharpExample
{
    public class BloombergArrayResponse
    {
        [JsonProperty("data")]
        public List<BloombergInstrument> data { get; set; }
    }
}
