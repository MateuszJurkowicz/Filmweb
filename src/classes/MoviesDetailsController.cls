public with sharing class MoviesDetailsController {

    public static String generateImageUrl() {
        return 'https://image.tmdb.org/t/p/w600_and_h900_bestv2';
    }

    @AuraEnabled(cacheable=true) public static List<Movie__c> loadAllMovies(String name, String searchKey) {
        List<Movie__c> movies = new List<Movie__c>();
        String Endpoint = '';

        if (String.isNotBlank(searchKey) && name != 'Favorite movies' && name != 'To watch movies') {
            Endpoint = 'https://api.themoviedb.org/3/search/movie?query=' + searchKey + '&include_adult=false&language=en-US&page=1';
            movies = fetchMoviesFromEndpoint(Endpoint);
        } else if (String.isNotBlank(searchKey) && name == 'Favorite movies') {
            List<Movie__c> favoriteMovies = [
                    SELECT Movie_Id__c, Name
                    FROM Movie__c
                    WHERE Is_Favorited__c = TRUE AND Name LIKE :('%' + searchKey + '%')
            ];
            if (!favoriteMovies.isEmpty()) {
                List<Integer> favoriteMovieIds = new List<Integer>();
                for (Movie__c movie : favoriteMovies) {
                    favoriteMovieIds.add((Integer) movie.Movie_Id__c);
                }
                movies = fetchMoviesFromApi(favoriteMovieIds);
            }
        } else if (String.isNotBlank(searchKey) && name == 'To watch movies') {
            List<Movie__c> toWatchMovies = [
                    SELECT Movie_Id__c, Name
                    FROM Movie__c
                    WHERE Is_In_Watch_List__c = TRUE AND Name LIKE :('%' + searchKey + '%')
            ];
            if (!toWatchMovies.isEmpty()) {
                List<Integer> toWatchMovieIds = new List<Integer>();
                for (Movie__c movie : toWatchMovies) {
                    toWatchMovieIds.add((Integer) movie.Movie_Id__c);
                }
                movies = fetchMoviesFromApi(toWatchMovieIds);
            }
        } else if (name == 'Popular movies' && String.isBlank(searchKey)) {
            Endpoint = 'https://api.themoviedb.org/3/movie/popular?language=en-US&page=1&region=PL';
            movies = fetchMoviesFromEndpoint(Endpoint);
        } else if (name == 'Top rated movies' && String.isBlank(searchKey)) {
            Endpoint = 'https://api.themoviedb.org/3/movie/top_rated?language=en-US&page=1&region=PL';
            movies = fetchMoviesFromEndpoint(Endpoint);
        } else if (name == 'Favorite movies' && String.isBlank(searchKey)) {
            List<Movie__c> favoriteMovies = [SELECT Movie_Id__c FROM Movie__c WHERE Is_Favorited__c = TRUE];
            if (!favoriteMovies.isEmpty()) {
                List<Integer> favoriteMovieIds = new List<Integer>();
                for (Movie__c movie : favoriteMovies) {
                    favoriteMovieIds.add((Integer) movie.Movie_Id__c);
                }
                movies = fetchMoviesFromApi(favoriteMovieIds);
            }
        } else if (name == 'To watch movies' && String.isBlank(searchKey)) {
            List<Movie__c> toWatchMovies = [SELECT Movie_Id__c FROM Movie__c WHERE Is_In_Watch_List__c = TRUE];
            if (!toWatchMovies.isEmpty()) {
                List<Integer> favoriteMovieIds = new List<Integer>();
                for (Movie__c movie : toWatchMovies) {
                    favoriteMovieIds.add((Integer) movie.Movie_Id__c);
                }
                movies = fetchMoviesFromApi(favoriteMovieIds);
            }
        }

        return movies;
    }

    public static List<Movie__c> fetchMoviesFromApi(List<Integer> movieIds) {
        List<Movie__c> movies = new List<Movie__c>();

        for (Integer movieId : movieIds) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.themoviedb.org/3/movie/' + movieId + '?language=en-US');
                req.setMethod('GET');
                req.setHeader('accept', 'application/json');
                req.setHeader('Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMzAyMDE5Ny44ODg3NTEsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.-IbNV34APBJfZRMNMCXOu9OoHu07Qy8EjMOdl92fONU');

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    Movie__c movie = new Movie__c();
                    movie.Movie_Id__c = (Integer) result.get('id');
                    movie.Name = (String) result.get('title');
                    movie.Overview__c = (String) result.get('overview');
                    movie.Release_Date__c = Date.valueOf((String) result.get('release_date'));
                    movie.Poster_URL__c = 'https://image.tmdb.org/t/p/w500' + (String) result.get('poster_path');
                    movie.Vote_Average__c = ((Decimal) result.get('vote_average')) * 10;
                    movie.Vote_Count__c = (Decimal) result.get('vote_count');
                    movie.Is_Favorited__c = isFilmFavorite((Integer) movie.Movie_Id__c);
                    movie.Is_In_Watch_List__c = isFilmInWatchList((Integer) movie.Movie_Id__c);

                    movies.add(movie);
                } else {
                    System.debug('Failed to get data for movie ID ' + movieId + '. Status code: ' + res.getStatusCode());
                }
            } catch (Exception e) {
                System.debug('Exception fetching data for movie ID ' + movieId + ': ' + e.getMessage());
            }
        }

        return movies;
    }

    public static List<Movie__c> fetchMoviesFromEndpoint(String endpoint) {
        List<Movie__c> movies = new List<Movie__c>();

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
                    Map<String, Object> movieData = (Map<String, Object>) obj;

                    Movie__c movie = new Movie__c();
                    movie.Movie_Id__c = (Integer) movieData.get('id');
                    movie.Name = (String) movieData.get('title');
                    movie.Overview__c = (String) movieData.get('overview');
                    movie.Release_Date__c = Date.valueOf((String) movieData.get('release_date'));
                    movie.Poster_URL__c = 'https://image.tmdb.org/t/p/w500' + (String) movieData.get('poster_path');
                    movie.Vote_Average__c = ((Decimal) movieData.get('vote_average')) * 10;
                    movie.Vote_Count__c = (Decimal) movieData.get('vote_count');
                    movie.Is_Favorited__c = isFilmFavorite((Integer) movie.Movie_Id__c);
                    movie.Is_In_Watch_List__c = isFilmInWatchList((Integer) movie.Movie_Id__c);

                    movies.add(movie);
                }
            } else {
                System.debug('Failed to get data from API. Status code: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }

        return movies;
    }


    @AuraEnabled(Cacheable=true) public static Movie__c getMovieDetails(Integer movieId) {

        Movie__c movie = new Movie__c();

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.themoviedb.org/3/movie/' + movieId + '?language=en-US&page=1&region=PL');
            req.setMethod('GET');
            req.setHeader('accept', 'application/json');
            req.setHeader('Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMzAyMDE5Ny44ODg3NTEsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.-IbNV34APBJfZRMNMCXOu9OoHu07Qy8EjMOdl92fONU');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                System.debug('res getbody ' + res.getBody());

                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('result ' + result);

                movie.Movie_Id__c = (Integer) result.get('id');
                movie.Name = (String) result.get('title');
                movie.Overview__c = (String) result.get('overview');
                movie.Release_Date__c = Date.valueOf((String) result.get ('release_date'));
                movie.Runtime__c = (Integer) result.get('runtime');
                movie.Budget__c = (Integer) result.get('budget');
                movie.Poster_URL__c = (String) (generateImageUrl() + result.get ('poster_path'));
                movie.Vote_Average__c = ((Decimal) result.get('vote_average')) * 10;
                movie.Vote_Count__c = (Decimal) result.get('vote_count');
                movie.Is_Favorited__c = isFilmFavorite((Integer) movie.Movie_Id__c);
                movie.Is_In_Watch_List__c = isFilmInWatchList((Integer) movie.Movie_Id__c);

                System.debug('movie: ' + movie);

            } else {
                System.debug('Failed to get data from API. Status code: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        return movie;
    }

    @AuraEnabled public static Boolean isFilmFavorite(Integer Movie_Id) {
        List<Movie__c> movieTemp = [
                SELECT Is_Favorited__c
                FROM Movie__c
                WHERE Movie_Id__c = :Movie_Id AND Is_Favorited__c = TRUE
        ];

        System.debug(movieTemp.size());

        if (movieTemp.size() == 1) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled public static Boolean isFilmInWatchList(Integer Movie_Id) {
        List<Movie__c> movieTemp = [
                SELECT Is_In_Watch_List__c
                FROM Movie__c
                WHERE Movie_Id__c = :Movie_Id AND Is_In_Watch_List__c = TRUE
        ];

        System.debug(movieTemp.size());

        if (movieTemp.size() == 1) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled public static Boolean saveCommentToMovie(String content, Integer movieId) {
        Id currentUserId = UserInfo.getUserId();

        System.debug('CURRENT USER ID ' + currentUserId);

        Integer existingCommentsCount = [SELECT COUNT() FROM Comment__c WHERE Movie_Id__c = :movieId AND CreatedById = :currentUserId];

        System.debug('existingCommentsCount ' + existingCommentsCount);
        if (existingCommentsCount == 0) {
            Comment__c newComment = new Comment__c();
            newComment.Movie_Id__c = movieId;
            newComment.Content__c = content;
            insert newComment;
            return true;
        } else {
            System.debug('You have already commented on this movie.');
            return false;
        }
    }


    @AuraEnabled public static List<Map<String, Object>> getMovieComments(Integer movieId) {
        List<Map<String, Object>> formattedComments = new List<Map<String, Object>>();

        List<Comment__c> comments = [SELECT Name, Content__c, CreatedDate, CreatedBy.Name FROM Comment__c WHERE Movie_Id__c = :movieId ORDER BY CreatedDate ASC];

        for (Comment__c c : comments) {
            Map<String, Object> commentMap = new Map<String, Object>();
            commentMap.put('Name', c.Name);
            commentMap.put('Content__c', c.Content__c);
            commentMap.put('CreatedDate', c.CreatedDate.format('dd.MM.yyyy HH:mm:ss'));
            commentMap.put('CreatedByName', c.CreatedBy.Name);

            formattedComments.add(commentMap);
        }
        System.debug(formattedComments);
        return formattedComments;
    }


    @AuraEnabled public static void changeFavoriteStatus(Integer movieId) {
        if (isFilmFavorite((Integer) movieId) && !isFilmInWatchList((Integer) movieId)) {
            Movie__c movie = [SELECT Id, Is_Favorited__c FROM Movie__c WHERE Movie_Id__c = :movieId LIMIT 1];
            delete movie;
        } else if (!isFilmFavorite((Integer) movieId) && isFilmInWatchList((Integer) movieId)) {
            Movie__c movie = [SELECT Id, Is_Favorited__c FROM Movie__c WHERE Movie_Id__c = :movieId LIMIT 1];
            movie.Is_Favorited__c = true;
            update movie;
        } else if (isFilmFavorite((Integer) movieId) && isFilmInWatchList((Integer) movieId)) {
            Movie__c movie = [SELECT Id, Is_Favorited__c FROM Movie__c WHERE Movie_Id__c = :movieId LIMIT 1];
            movie.Is_Favorited__c = false;
            update movie;
        } else {
            Movie__c movie = getMovieDetails(movieId);
            movie.Is_Favorited__c = true;
            insert movie;
        }
    }

    @AuraEnabled public static void changeToWatchStatus(Integer movieId) {
        if (!isFilmFavorite((Integer) movieId) && isFilmInWatchList((Integer) movieId)) {
            Movie__c movie = [SELECT Id, Is_In_Watch_List__c FROM Movie__c WHERE Movie_Id__c = :movieId LIMIT 1];
            delete movie;
        } else if (isFilmFavorite((Integer) movieId) && !isFilmInWatchList((Integer) movieId)) {
            Movie__c movie = [SELECT Id, Is_In_Watch_List__c FROM Movie__c WHERE Movie_Id__c = :movieId LIMIT 1];
            movie.Is_In_Watch_List__c = true;
            update movie;
        } else if (isFilmFavorite((Integer) movieId) && isFilmInWatchList((Integer) movieId)) {
            Movie__c movie = [SELECT Id, Is_In_Watch_List__c FROM Movie__c WHERE Movie_Id__c = :movieId LIMIT 1];
            movie.Is_In_Watch_List__c = false;
            update movie;
        } else {
            Movie__c movie = getMovieDetails(movieId);
            movie.Is_In_Watch_List__c = true;
            insert movie;
        }
    }
}