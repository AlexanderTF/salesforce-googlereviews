public class GooglePlacesService {

    // Optional: Retrieve API key if not added as a custom header in Named Credential
    public static String getApiKey() {
        GoogleAPISettings__c customSetting = GoogleAPISettings__c.getInstance();
        return customSetting.API_Key__c;
    }

    // Method to perform text search using Google Places API
    @future(callout=true)
    public static void searchText(String textQuery) {
        // Construct the endpoint using Named Credential
        String endpoint = 'https://places.googleapis.com/v1/places:searchText';

        // JSON body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'textQuery' => textQuery
        });

        // Set up the Http request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        // Set API key header if not stored in Named Credential
        String apiKey = getApiKey();
        request.setHeader('X-Goog-Api-Key', apiKey);

        // Specify fields to retrieve using FieldMask header
        request.setHeader('X-Goog-FieldMask', 'places.id,places.displayName,places.formattedAddress');

        // Set the request body
        request.setBody(jsonBody);

        try {
            // Send the HTTP request
            HttpResponse response = http.send(request);

            // Check the response
            if (response.getStatusCode() == 200) {
                // Successful response handling
                String responseBody = response.getBody();
                System.debug('Response Body: ' + responseBody);
            } else {
                // Handle errors
                System.debug('Error: HTTP Status ' + response.getStatus());
                System.debug('Response Body: ' + response.getBody());
                throw new CalloutException('Error: HTTP Status ' + response.getStatus() + ' Body: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @future(callout=true)
    public static void getPlaceReviews(String placeId) {
        // Construct the endpoint using Named Credential
        String endpoint = 'https://places.googleapis.com/v1/places/' + placeId;

        // Set up the HttpRequest
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');

        // Set API key header if not stored in Named Credential
        String apiKey = getApiKey();
        request.setHeader('X-Goog-Api-Key', apiKey);
        request.setHeader('X-Goog-FieldMask', 'id,reviews');

        try {
            // Send the HTTP request
            HttpResponse response = http.send(request);

            // Check the response
            if (response.getStatusCode() == 200) {
                // Handle successful response
                String responseBody = response.getBody();
                //System.debug('Response Body: ' + responseBody);
                
               // Parse the response to extract reviews
               Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
               List<Object> reviews = (List<Object>) jsonResponse.get('reviews');
               
               // List to hold Cases for bulk insertion
               List<Case> casesToInsert = new List<Case>();

               for (Object reviewObj : reviews) {
                    Map<String, Object> review = (Map<String, Object>) reviewObj;
                    // Extract necessary fields
                    String author = (String) ((Map<String, Object>) review.get('authorAttribution')).get('displayName');
                    String uri = (String) ((Map<String, Object>) review.get('authorAttribution')).get('uri');
                    String rating = String.valueOf(review.get('rating'));
                    String reviewText = (String) ((Map<String, Object>) review.get('text')).get('text');

                    // Create a new Case
                    Case caseRecord = new Case();
                    caseRecord.RecordTypeId = '012bm000002w3qnAAA';
                    caseRecord.Description = reviewText; // Store review text in Description
                    caseRecord.Review_uri__c = uri; // Store display name in Review_uri__c
                    caseRecord.Rating__c = rating; // Store rating in rating__c
                    caseRecord.Review_Author__c = author;
                    caseRecord.Subject = author + ' - Rating: ' + rating;
                    caseRecord.Origin = 'Web';

                    casesToInsert.add(caseRecord);
                    System.debug('Saving review by ' + author);
               }

               // Insert Cases in bulk
               if (!casesToInsert.isEmpty()) {
                    // Set allOrNone to false for partial success
                    Database.SaveResult[] results = Database.insert(casesToInsert, false);
                
                    // Loop through results to log any errors
                    for (Integer i = 0; i < results.size(); i++) {
                        if (!results[i].isSuccess()) {
                            for (Database.Error error : results[i].getErrors()) {
                                System.debug('Error inserting Case: ' + error.getMessage());
                            }
                        } else {
                            System.debug('Successfully inserted Case: ' + casesToInsert[i].Id);
                        }
                    }
                }
            } else {
                // Handle errors
                throw new CalloutException('Error: HTTP Status ' + response.getStatus());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
}
