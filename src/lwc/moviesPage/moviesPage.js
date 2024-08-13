import { LightningElement, track, api } from 'lwc';
import loadAllMovies from '@salesforce/apex/MoviesDetailsController.loadAllMovies';
import {NavigationMixin} from 'lightning/navigation';
import NO_AVATAR_IMAGE from "@salesforce/resourceUrl/no_avatar";
import changeFavoriteStatus from '@salesforce/apex/MoviesDetailsController.changeFavoriteStatus';
import changeToWatchStatus from '@salesforce/apex/MoviesDetailsController.changeToWatchStatus';

const options = {
    method: 'GET',
    headers: {
        accept: 'application/json',
        Authorization: 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMjUwMDI1Ny44OTE5MjIsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.ZPhTVcKb9s3RgUh3ExUBGEU2HgFVDskupW1aKlgTnBw'
    }
};

export default class MoviesPage extends NavigationMixin(LightningElement) {
    @api name;
    @track movies = [];
    @track searchKey = '';
    isLoading = false;

    connectedCallback() {
        this.fetchMoviesData();
        console.log('NAME ' + this.name);
        this.template.addEventListener('search', this.handleSearch.bind(this));
    }

    fetchMoviesData() {
        this.isLoading = true;
        loadAllMovies({ name: this.name, searchKey: this.searchKey})
            .then(result => {
                console.log('Movies data: ', result);
                this.movies = result.map(movie => {
                    return Object.assign({}, movie, {
                        favoriteName: movie.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt',
                        toWatchName: movie.Is_In_Watch_List__c ? 'utility:check' : 'utility:clock'
                    });
                });
                console.log('Movies loaded successfully');
            })
            .catch(error => {
                this.movies = null;
                console.error('Error loading movies', error);
            })
            .finally(() => {
                this.isLoading = false;
            })
    }


    navigateToMovieDetailPage(event) {
        event.preventDefault();
        const movieId = event.currentTarget.dataset.id;
        console.log(' Movie ID ' + movieId);

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Movie_Detail_Page',
            },
            state: {
                c__movieId: movieId,
            },
        });
    }

    favoriteClick(event) {
        event.preventDefault();
        const movieId = event.target.dataset.id;
        console.log('Movie ID FAVORITE ' + movieId);

        changeFavoriteStatus({ movieId: movieId })
            .then(() => {
                console.log('Favorite status updated successfully.');

                let movie = this.movies.find(mov => mov.Movie_Id__c == movieId);
                if (movie) {
                    console.log("Movie ");
                    movie.Is_Favorited__c = !movie.Is_Favorited__c;
                    console.log("Movie is favorited: " + movie.Is_Favorited__c);
                    movie.favoriteName = movie.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt';
                    console.log("Movie favoriteName: " + movie.favoriteName);
                }

            })
            .catch(error => {
                console.error('Error updating favorite status: ', error);
            });
    }

    toWatchClick(event) {
        event.preventDefault();
        const movieId = event.target.dataset.id;
        console.log('Movie ID FAVORITE ' + movieId);

        changeToWatchStatus({ movieId: movieId })
            .then(() => {
                console.log('Watch status updated successfully.');

                let movie = this.movies.find(mov => mov.Movie_Id__c == movieId);
                if (movie) {
                    console.log("Movie ");
                    movie.Is_In_Watch_List__c = !movie.Is_In_Watch_List__c;
                    console.log("Movie is in watch list: " + movie.Is_In_Watch_List__c);
                    movie.toWatchName = movie.Is_In_Watch_List__c ? 'utility:check' : 'utility:clock';
                    console.log("Movie  toWatchName: " + movie.toWatchName);
                }

            })
            .catch(error => {
                console.error('Error updating favorite status: ', error);
            });
    }


     @api
     handleSearch(searchTerm) {
         this.searchKey = searchTerm;
         this.fetchMoviesData();
         console.log('Page searching ', this.name);
         console.log('MOVIES SEARCHING ', searchTerm);
     }

}