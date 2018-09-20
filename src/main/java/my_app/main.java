package my_app;

import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;

import org.json.JSONException;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

public class main {	
	public static void main(String[] args) {
		JSONParser parser = new JSONParser();
		 
        try {
        	// Load file with JSON
            Object obj = parser.parse(new FileReader("./statuses.json"));
            // Convert to JSON Object
            JSONObject jsonObject = (JSONObject) obj;
            // Get array of records from table "records"
            JSONArray records = (JSONArray) jsonObject.get("records");
            
            // Convert JSONArray to List of JSONObjects to use so0rting method from Collections
            List<JSONObject> jsonValues = new ArrayList<JSONObject>();
            
            // Chose date format
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            // Set date range to select records only after this date
            LocalDateTime date_range = LocalDateTime.parse("2017-07-01 00:00:00", formatter);
            
            for (int i = 0; i < records.size(); i++) {
            	JSONObject temp = (JSONObject) records.get(i);
                LocalDateTime get_date = LocalDateTime.parse((String) temp.get("kontakt_ts"), formatter);
                //System.out.println(get_date);
                
                // For every row, insert only these which contains date after first of July 2017
                if(get_date.isAfter(date_range))
                	jsonValues.add((JSONObject) records.get(i));
            }
            
            
            // Create object of sorted records
            JSONArray sortedJsonArray = new JSONArray();
            
            // Sort our collection with custom comparator
            Collections.sort(jsonValues, new Comparator<JSONObject>() {
                // We compare records by client's ID and contact timestamp
                private static final String KEY_NAME_1 = "klient_id";
                private static final String KEY_NAME_2 = "kontakt_ts";

                public int compare(JSONObject a, JSONObject b) {
                	Long valA = new Long(0);
                	Long valB = new Long(0);

                    
                   valA = (Long) a.get(KEY_NAME_1);
                   valB = (Long) b.get(KEY_NAME_1);
                   
                   // Compare ID's and sort ascending
                   int compare_kontakt =  valA.compareTo(valB);
                   
                   // If ID's are not equal return result and if not, compare dates aswell
                   if (compare_kontakt != 0) {
                	   return compare_kontakt;
                   }
                   
                   DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
                   LocalDateTime valC = LocalDateTime.parse((String) a.get(KEY_NAME_2), formatter);
                   LocalDateTime valD = LocalDateTime.parse((String) b.get(KEY_NAME_2), formatter);
                   
                   // Sort by date ascending
                   return valC.compareTo(valD);
                }
            });
            
            
            // Rewrite list to JSONArray
            for (int i = 0; i < jsonValues.size(); i++) {
                sortedJsonArray.add(jsonValues.get(i));
            }
            
            // Create head of CSV file
            PrintWriter pw = new PrintWriter(new File("client_data.csv"));
            StringBuilder sb = new StringBuilder();
            sb.append("kontakt_id"); sb.append(";");
            sb.append("klient_id"); sb.append(";");
            sb.append("pracownik_id"); sb.append(";");
            sb.append("status"); sb.append(";");
            sb.append("kontakt_ts"); sb.append("\n");
            
            // Appent every record to file
            for (int i = 0; i < sortedJsonArray.size(); i++) {
            	JSONObject temp = (JSONObject) sortedJsonArray.get(i);
            	sb.append(temp.get("kontakt_id")); sb.append(";");
                sb.append(temp.get("klient_id")); sb.append(";");
                sb.append(temp.get("pracownik_id")); sb.append(";");
                sb.append(temp.get("status")); sb.append(";");
                sb.append(temp.get("kontakt_ts")); sb.append("\n");
            }

            pw.write(sb.toString());
            pw.close();
            System.out.println("CSV file created successfully!");
        } catch (Exception e) {
        	// Something went wrong :(
            e.printStackTrace();
        }
	}
}