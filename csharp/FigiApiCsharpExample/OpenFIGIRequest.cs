using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace FigiApiCsharpExample
{
    public class OpenFIGIRequest
    {
        private static readonly string[] ExchangeCodes = new[] { "A0", "AB", "AG", "AI", "AL", "AR", "AU", "AV", "AY", "AZ", "B3", "BA", "BB", "BC", "BD", "BG", "BH", "BI", "BK", "BM", "BQ", "BT", "BU", "BY", "BZ", "C1", "CB", "CH", "CI", "CN", "CP", "CR", "CY", "CZ", "DC", "DE", "DU", "DX", "EB", "ED", "EK", "EL", "EO", "ES", "ET", "EU", "EY", "FH", "FP", "FS", "GA", "GG", "GL", "GN", "GR", "GU", "H1", "HB", "HK", "HM", "HO", "IA", "ID", "IE", "IJ", "IM", "IN", "IQ", "IR", "IT", "IX", "JA", "JP", "JR", "JY", "K3", "KB", "KF", "KH", "KK", "KN", "KS", "KY", "KZ", "L3", "LB", "LD", "LH", "LI", "LN", "LR", "LS", "LX", "LY", "MB", "MC", "ME", "MK", "MM", "MO", "MP", "MQ", "MS", "MT", "MV", "MW", "MX", "MZ", "NA", "NC", "NK", "NL", "NO", "NQ", "NR", "NW", "NX", "NZ", "OM", "PA", "PB", "PE", "PG", "PL", "PM", "PN", "PO", "PP", "PS", "PW", "PX", "PZ", "QD", "QM", "QT", "QX", "RB", "RM", "RO", "RU", "RW", "S1", "S2", "SD", "SG", "SJ", "SK", "SL", "SM", "SP", "SS", "SV", "SW", "SY", "SZ", "TB", "TE", "TH", "TI", "TL", "TP", "TQ", "TT", "TU", "TZ", "UG", "UH", "US", "UY", "UZ", "VB", "VC", "VN", "VR", "VX", "ZH", "ZL", "ZS", "ZU" };
        private static readonly string[] YellowKeys = { "Govt", "Corp", "Mtge", "M-Mkt", "Muni", "Pfd", "Equity", "Comdty", "Curncy", "Index" };

        private static readonly Regex Isin = new Regex("[a-zA-Z]{2}\\w{10}");
        private static readonly Regex Figi = new Regex("BBG\\w{9}");

        public OpenFIGIRequest(string value)
        {
            marketSecDes = GetMarketSector(value) ?? "";
            exchCode = GetExchangeCode(value) ?? "";
            if (!string.IsNullOrEmpty(marketSecDes))
                value = value.Replace(marketSecDes, string.Empty);
            if (!string.IsNullOrEmpty(exchCode))
                value = value.Replace(exchCode, string.Empty);
            if (!string.IsNullOrEmpty(value))
                idValue = string.Join(" ", value.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries));


            idType = "TICKER";
            if (!string.IsNullOrEmpty(idValue))
            {
                if (Figi.IsMatch(idValue))
                    idType = "ID_BB_GLOBAL";
                else if (Isin.IsMatch(idValue))
                    idType = "ID_ISIN";
            }
        }


        [JsonProperty("idType")]
        public string idType { get; set; }
        //[XmlElement("idValue")]
        [JsonProperty("idValue")]
        public string idValue { get; set; }
        //[XmlElement("exchCode")]
        [JsonProperty("exchCode")]
        public string exchCode { get; set; }
        //[XmlElement("marketSecDes")]
        [JsonProperty("marketSecDes")]
        public string marketSecDes { get; set; }


        private static string GetMarketSector(string value)
        {
            if (string.IsNullOrEmpty(value)) return null;
            return value.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).Reverse().FirstOrDefault(x => YellowKeys.Contains(x));
        }

        private static string GetExchangeCode(string value)
        {
            if (string.IsNullOrEmpty(value)) return null;
            return value.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).Reverse().FirstOrDefault(x => ExchangeCodes.Contains(x));
        }

    }
}
