using Newtonsoft.Json;

namespace FigiApiCsharpExample
{
    public class NewtonsoftJsonSerializer : IJsonSerializer
    {
        private JsonSerializerSettings settings;


        public NewtonsoftJsonSerializer()
        {
            this.settings = new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore };
        }


        public string ContentType
        {
            get { return "application/json"; } // Probably used for Serialization?
            set { }
        }

        public string DateFormat { get; set; }

        public string Namespace { get; set; }

        public string RootElement { get; set; }


        public string Serialize(object obj)
        {
            return JsonConvert.SerializeObject(obj, settings);
        }

        public T Deserialize<T>(RestSharp.IRestResponse response)
        {
            var content = response.Content;
            return JsonConvert.DeserializeObject<T>(content, settings);
        }
    }
}
