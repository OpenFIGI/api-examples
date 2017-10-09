import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;

public class Example {
    public static void main(String[] args) throws Exception {
        Example app = new Example();
        String apiKey = "";
        List<Job> jobs = new ArrayList<Job>();

        jobs.add(app.createJob("ID_WERTPAPIER", "851399").currency("USD"));
        jobs.add(app.createJob("ID_BB_UNIQUE", "EQ0010080100001000").currency("USD"));
        jobs.add(app.createJob("ID_SEDOL", "2005973").micCode("EDGX").currency("USD"));

        List<JobResult> jobResults = app.mapJobs(apiKey, jobs);

        int i = 0;
        for (JobResult result : jobResults) {
            i+=1;
            System.out.println(String.format("Query #%d results\n", i));
            System.out.println(result.toString());
            System.out.println("\n");
        }
    }

    private Job createJob(String idType, String idValue) {
        return new Job(idType, idValue);
    }

    private static String join(String sep, List<String> list) {
        if (list.size() == 0) {
            return "";
        }

        StringBuilder sb = new StringBuilder(list.get(0));

        for(int i = 1, len = list.size(); i < len; i++) {
            sb.append(sep).append(list.get(i));
        }

        return sb.toString();
    }

    private static String listJobsToJson(List<Job> jobs) {
        List<String> jobsJson = new ArrayList<String>();

        for (Job job : jobs) {
            jobsJson.add(job.toJsonObject());
        }

        return "[" + join(",", jobsJson) + "]";
    }

    private List<JobResult> responseJsonToListJobResult(String json) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<JobResult> jobResults = mapper.readValue(json, new TypeReference<List<JobResult>>(){});;

        return jobResults;
    }

    private static String listJobResultsToString(List<JobResult> jobResults) {
        List<String> jobResultStrs = new ArrayList<String>();

        for (JobResult jobResult : jobResults) {
            jobResultStrs.add(jobResult.toString());
        }

        return join("\n", jobResultStrs);
    }

    private List<JobResult> mapJobs(String apiKey, List<Job> jobs) throws Exception {
        String url = "https://api.openfigi.com/v1/mapping";
        URL obj = new URL(url);
        HttpURLConnection con = (HttpURLConnection) obj.openConnection();

        con.setRequestMethod("POST");
        con.setRequestProperty("Content-Type","application/json");

        if (apiKey != null && apiKey != "") {
            con.setRequestProperty("X-OPENFIGI-APIKEY", apiKey);
        }

        String postJsonData = listJobsToJson(jobs);

        con.setDoOutput(true);
        DataOutputStream wr = new DataOutputStream(con.getOutputStream());
        wr.writeBytes(postJsonData);
        wr.flush();
        wr.close();

        int responseCode = con.getResponseCode();
        BufferedReader in = new BufferedReader(
            new InputStreamReader(con.getInputStream()));
        String output;
        StringBuffer response = new StringBuffer();

        while ((output = in.readLine()) != null) {
            response.append(output);
        }
        in.close();

        String responseJson = response.toString();

        return responseJsonToListJobResult(responseJson);
    }

    /* Job class */

    public class Job {
        private String idType, idValue, exchCode, micCode, currency,
            marketSecDes;

        public Job(String idType, String idValue) {
            this.idType = idType;
            this.idValue = idValue;
            this.exchCode = null;
            this.micCode = null;
            this.currency = null;
            this.marketSecDes = null;
        }

        public Job exchCode(String exchCode) {
            this.exchCode = exchCode;
            return this;
        }

        public Job micCode(String micCode) {
            this.micCode = micCode;
            return this;
        }

        public Job currency(String currency) {
            this.currency = currency;
            return this;
        }

        public Job marketSecDes(String marketSecDes) {
            this.marketSecDes = marketSecDes;
            return this;
        }

        public String toJsonObject() {
            StringBuilder jsonSb = new StringBuilder("{");

            jsonSb.append(jsonKeyValuePair("idType", this.idType))
                .append(",")
                .append(jsonKeyValuePair("idValue", this.idValue));

            if (this.exchCode != null) {
                jsonSb.append(",").append(jsonKeyValuePair("exchCode", this.exchCode));
            }

            if (this.micCode != null) {
                jsonSb.append(",").append(jsonKeyValuePair("micCode", this.micCode));
            }

            if (this.currency != null) {
                jsonSb.append(",").append(jsonKeyValuePair("currency", this.currency));
            }

            if (this.marketSecDes != null) {
                jsonSb.append(",").append(jsonKeyValuePair("marketSecDes", this.marketSecDes));
            }

            return jsonSb.append("}").toString();
        }

        private String jsonKeyValuePair(String key, String value) {
            return "\"" + key + "\":\"" + value + "\"";
        }
    }

    /* Figi class */

    static class Figi {
        public String figi, securityType, marketSector, ticker, name, uniqueID,
            exchCode, shareClassFIGI, compositeFIGI, securityType2,
            securityDescription, uniqueIDFutOpt;

        public String toString() {
            return (new StringBuilder())
                .append("figi: ").append(this.figi).append("\n")
                .append("securityType: ").append(this.securityType).append("\n")
                .append("marketSector: ").append(this.marketSector).append("\n")
                .append("ticker: ").append(this.ticker).append("\n")
                .append("name: ").append(this.name).append("\n")
                .append("uniqueID: ").append(this.uniqueID).append("\n")
                .append("exchCode: ").append(this.exchCode).append("\n")
                .append("shareClassFIGI: ").append(this.shareClassFIGI).append("\n")
                .append("compositeFIGI: ").append(this.compositeFIGI).append("\n")
                .append("securityType2: ").append(this.securityType2).append("\n")
                .append("securityDescription: ").append(this.securityDescription).append("\n")
                .append("uniqueIDFutOpt: ").append(this.uniqueIDFutOpt)
                .append("\n")
                .toString();
        }
    }

    /* JobResult Class */

    static class JobResult {
        public String error;
        public List<Figi> data;

        public String toString() {
            if (error != null) {
                return error;
            }

            List<String> figiStrs = new ArrayList<String>();

            for (Figi figi : data) {
                figiStrs.add(figi.toString());
            }

            return join("\n", figiStrs);
        }
    }
}
