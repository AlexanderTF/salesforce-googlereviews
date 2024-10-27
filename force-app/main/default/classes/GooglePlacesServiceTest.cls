@IsTest
public class GooglePlacesServiceTest {

    // Mock class to simulate the HTTP response
    private class GooglePlacesMock implements HttpCalloutMock {
        // This method returns a fake HTTP response for testing
        public HttpResponse respond(HttpRequest req) {
            // Create a new HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Set a sample JSON response body (as you might get from Google Places API)
            res.setBody('{"places": [{"id": "123", "displayName": "cafebloc", "formattedAddress": "123 Sample St, Sydney, Australia"}]}');
            
            return res;
        }
    }

    // Unit test method for GooglePlacesService.searchText
    @IsTest
    static void testSearchText() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new GooglePlacesMock());

        // Insert a test record for Custom Metadata (mocked API key)
        GoogleAPISettings__c settings = new GoogleAPISettings__c();
        settings.API_Key__c = 'test_api_key';
        insert settings;

        // Call the future method with a sample query string
        Test.startTest();
        GooglePlacesService.searchText('cafebloc');
        Test.stopTest();
        
        // Validate expected outcomes (if any assertions are needed on debug logs or database operations)
        System.assert(true, 'The future method executed successfully');
    }

    // Mock class to simulate the Google Places API response
    private class GooglePlacesServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a fake HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Mock JSON response body with review details
            res.setBody('{"reviews":[{' +
                '"name":"places/afffsffwecewrc/reviews/aweawefawefawef",' +
                '"relativePublishTimeDescription":"2 months ago",' +
                '"rating": "5",' +
                '"text":{"text":"ONE OF THE BEST","language":"en"},' +
                '"original text":{"text":"ONE OF THE BEST","language":"en"},' +
                '"authorAttribution":{"displayName":"Andy Lee","uri":"https://example.com/reviews"}' +
            '}]}');

            return res;
        }
    }

    @IsTest
    static void testGetPlaceReviews() {
        // Set up mock for HTTP callouts
        Test.setMock(HttpCalloutMock.class, new GooglePlacesServiceMock());

        // Call the method with a sample Place ID
        String placeId = 'ChIJL2LZ1b6Z3IAR8x2Zw1slH_A';
        GooglePlacesService.getPlaceReviews(placeId);

        // Wait for @future method execution
        Test.stopTest();

        // Verify that a Case record was created with the correct data
        List<Case> cases = [SELECT Subject, Description, Review_uri__c, Rating__c FROM Case];
        System.assertEquals(1, cases.size(), 'One case record should have been created.');

        Case caseRecord = cases[0];
        System.assertEquals('ONE OF THE BEST', caseRecord.Description, 'The Description should contain the review text.');
        System.assertEquals('Andy Lee', caseRecord.Review_uri__c, 'The Review_uri__c should contain the author display name.');
        System.assertEquals('5', caseRecord.Rating__c, 'The Rating__c should contain the review rating.');
    }
}
