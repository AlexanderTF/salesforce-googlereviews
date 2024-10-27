# Google Places API Integration in Salesforce

## Overview
This project integrates the Google Places API with Salesforce to retrieve place details, including reviews and ratings, and store them in the standard Salesforce Case object. This integration helps users access up-to-date information from Google Places directly within Salesforce.

## Features
- **Retrieve Reviews**: Fetches place reviews from Google Places, including author name, rating, and review text.
- **Save in Case Object**: Stores each review in Salesforce Cases, with fields for author, rating, and review text.
- **Partial Data Loading**: Supports partial loading of Cases to handle errors for individual records.
- **Custom Subject Creation**: The Case subject field includes the review author and rating for better clarity and organization.

## Setup Instructions

### 1. Google Cloud Project Setup
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project or select an existing one.
3. Enable the **Places API (New)** for your project.
4. Go to **Credentials** and create an API key. Note this key, as it will be used in Salesforce.
5. Configure the API key’s restrictions, if necessary.

### 2. Salesforce Configuration

#### Custom Setting to store API Key
1. In Salesforce, go to **Setup** > **Custom Settings**.
2. Create a new Custom Setting named `GoogleAPISettings`.
3. Add a custom text field called `API_Key__c` to store the Google Places API key.

### 3. Custom Fields on Case
1. Go to **Object Manager** > **Case** > **Fields & Relationships**.
2. Add the following custom fields:
   - **Rating__c**: Picklist to store review ratings from 1 to 5.
   - **Review_uri__c**: Text field for storing the author’s google review page.
   - **Review_Author__c**: Text field for storing the author's Google username.

### 4. Apex Code Deployment
1. Deploy the `GooglePlacesService` Apex class into your Salesforce org.
2. Ensure all permissions for making callouts are properly configured.

## Code Explanation

### GooglePlacesService
The `GooglePlacesService` class contains methods to call the Google Places API and parse its responses:

- **`getApiKey`**: Retrieves the Google API key from Custom Metadata.
- **`getPlaceReviews`**: Makes a GET request to the Google Places API to retrieve reviews for a given place ID.
  - **Request Structure**: The method constructs a JSON body for the API request and sets headers for authentication and field masking.
  - **Partial Insert**: Uses `Database.insert` with `allOrNone = false` to allow partial record insertions, handling any errors individually.

#### Example Code Snippet
```apex
@future(callout=true)
public static void getPlaceReviews(String placeId) {
    String endpoint = 'callout:Google_Places_Credentials/v1/places/' + placeId + '?fields=reviews';
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('GET');
    request.setHeader('X-Goog-Api-Key', getApiKey());
    request.setHeader('X-Goog-FieldMask', 'places.id,places.displayName,places.formattedAddress');
    // Additional logic...
}
```
#### Case Example
![Case example Screenshot](https://github.com/AlexanderTF/salesforce-googlereviews/blob/main/image/Case_Sample_Image.png)
## Next Steps
To go even further with the implementation, an API can be integrated to have a user reply to the reviews directly from Salesforce and publish it directly into Google.
Scheduled flow or Apex can also execute the Apex class on a daily basis.

