public with sharing class PersonsDetailsController {

    @AuraEnabled(cacheable=true)
    public static List<Person__c> loadAllPersons(String name, String searchKey) {
        List<Person__c> persons = new List<Person__c>();
        String Endpoint = '';

        if (String.isNotBlank(searchKey)) {
            Endpoint = 'https://api.themoviedb.org/3/search/person?query=' + searchKey + '&include_adult=false&language=en-US&page=1';
            persons = fetchPersonsFromEndpoint(Endpoint);
        } else if (name == 'Popular actors') {
            Endpoint = 'https://api.themoviedb.org/3/person/popular?language=en-US&page=1';
            persons = fetchPersonsFromEndpoint(Endpoint);
        } else if (name == 'Favorite actors') {
            List<Person__c> favoriteActors = [SELECT Actor_id__c FROM Person__c WHERE Is_Favorited__c = TRUE];
            System.debug('favoriteActors' + favoriteActors);
            if (!favoriteActors.isEmpty()) {
                List<Integer> favoriteActorsIds = new List<Integer>();
                System.debug('favoriteActorsIds' + favoriteActorsIds);
                for (Person__c person : favoriteActors) {
                    favoriteActorsIds.add((Integer) person.Actor_id__c);
                }
                persons = fetchPersonsFromApi(favoriteActorsIds);
            }
        } 

        return persons;
    }

    public static List<Person__c> fetchPersonsFromApi(List<Integer> personIds) {
        List<Person__c> persons = new List<Person__c>();

        for (Integer personId : personIds) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.themoviedb.org/3/person/' + personId + '?language=en-US');
                req.setMethod('GET');
                req.setHeader('accept', 'application/json');
                req.setHeader('Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMzAyMDE5Ny44ODg3NTEsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.-IbNV34APBJfZRMNMCXOu9OoHu07Qy8EjMOdl92fONU');

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    Person__c person = new Person__c();

                    person.Actor_id__c = (Integer) result.get('id');
                    person.Name = (String) result.get('name');
                    person.Picture__c = (String) (generateImageUrl() + result.get('profile_path'));
                    person.Is_Favorited__c = isPersonFavorite((Integer) person.Actor_id__c);

                    persons.add(person);
                } else {
                    System.debug('Failed to get data for person ID ' + personId + '. Status code: ' + res.getStatusCode());
                }
            } catch (Exception e) {
                System.debug('Exception fetching data for person ID ' + personId + ': ' + e.getMessage());
            }
        }

        return persons;
    }

    public static List<Person__c> fetchPersonsFromEndpoint(String endpoint) {
        List<Person__c> persons = new List<Person__c>();

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('accept', 'application/json');
            req.setHeader('Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMzAyMDE5Ny44ODg3NTEsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.-IbNV34APBJfZRMNMCXOu9OoHu07Qy8EjMOdl92fONU');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> results = (List<Object>) result.get('results');

                for (Object obj : results) {
                    Map<String, Object> personData = (Map<String, Object>) obj;

                    Person__c person = new Person__c();

                    person.Actor_id__c = (Integer) personData.get('id');
                    person.Name = (String) personData.get('name');
                    person.Picture__c = (String) (generateImageUrl() + personData.get('profile_path'));
                    person.Is_Favorited__c = isPersonFavorite((Integer) person.Actor_id__c);

                    persons.add(person);
                }
            } else {
                System.debug('Failed to get data from API. Status code: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }

        return persons;
    }

    @AuraEnabled(Cacheable=true) public static Person__c getPersonDetails(Integer personId) {

        Person__c person = new Person__c();

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.themoviedb.org/3/person/' + personId + '?language=en-US&page=1&region=PL');
            req.setMethod('GET');
            req.setHeader('accept', 'application/json');
            req.setHeader('Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMzAyMDE5Ny44ODg3NTEsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.-IbNV34APBJfZRMNMCXOu9OoHu07Qy8EjMOdl92fONU');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                System.debug('res getbody ' + res.getBody());

                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('result ' + result);

                person.Actor_id__c = (Integer) result.get('id');
                person.Name = (String) result.get('name');
                person.Biography__c = (String) result.get('biography');
                person.Birthday__c = Date.valueOf((String) result.get('birthday'));
                person.Place_of_birth__c = (String) result.get('place_of_birth');
                person.Picture__c = (String) (generateImageUrl() + result.get('profile_path'));
                person.Is_Favorited__c = isPersonFavorite((Integer) person.Actor_id__c);

                System.debug('person: ' + person);

            } else {
                System.debug('Failed to get data from API. Status code: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        return person;
    }

    @AuraEnabled public static Boolean isPersonFavorite(Integer Movie_Id) {
        List<Person__c> personTemp = [
                SELECT Is_Favorited__c
                FROM Person__c
                WHERE Actor_id__c = :Movie_Id AND Is_Favorited__c = TRUE
        ];

        System.debug(personTemp.size());

        if (personTemp.size() == 1) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled public static void changeFavoriteStatus(Integer personId) {
        if (isPersonFavorite((Integer) personId)) {
            Person__c person = [SELECT Id, Is_Favorited__c FROM Person__c WHERE Actor_id__c = :personId LIMIT 1];
            delete person;
        } else {
            Person__c person = getPersonDetails(personId);
            person.Is_Favorited__c = true;
            insert person;
        }
    }

    public static String generateImageUrl() {
        return 'https://media.themoviedb.org/t/p/w600_and_h900_bestv2';
    }
}