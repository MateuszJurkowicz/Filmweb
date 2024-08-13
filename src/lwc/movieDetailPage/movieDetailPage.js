import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMovieDetails from '@salesforce/apex/MoviesDetailsController.getMovieDetails';
import getMovieComments from '@salesforce/apex/MoviesDetailsController.getMovieComments';
import changeFavoriteStatus from '@salesforce/apex/MoviesDetailsController.changeFavoriteStatus';
import changeToWatchStatus from '@salesforce/apex/MoviesDetailsController.changeToWatchStatus';
import saveCommentToMovie from '@salesforce/apex/MoviesDetailsController.saveCommentToMovie';
import NO_AVATAR_IMAGE from "@salesforce/resourceUrl/no_avatar";

const options = {
    method: 'GET',
    headers: {
        accept: 'application/json',
        Authorization: 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMjUwMDI1Ny44OTE5MjIsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.ZPhTVcKb9s3RgUh3ExUBGEU2HgFVDskupW1aKlgTnBw'
    }
};

export default class MovieDetailPage extends NavigationMixin(LightningElement) {
    movieId;

    favoriteName = '';
    toWatchName = '';

    movie;
    @track comment;
    comments = [];
    @track hasUserCommented = false;

    @wire(CurrentPageReference)
    pageRef(data) {
        console.log(JSON.stringify(data));
        this.movieId = data.state.c__movieId;
        this.loadMovieDetails();
    }

    connectedCallback() {
        this.loadMovieDetails();

    }

    loadMovieDetails() {
        getMovieDetails({ movieId: this.movieId })
            .then(result => {
                this.movie = { ...result };
                this.favoriteName = this.movie.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt';
                this.toWatchName = this.movie.Is_In_Watch_List__c ? 'utility:check' : 'utility:clock';
                this.getMovieCast();
                this.loadMovieComments();
                console.log('Movie details loaded successfully: ', result);
            })
            .catch(error => {
                this.movie = null;
                console.error('Error loading movie details', error);
            });
    }

    favoriteClick(event) {
        event.preventDefault();
        const movieId = event.target.dataset.id;
        console.log('Movie ID FAVORITE ' + movieId);

        changeFavoriteStatus({ movieId: movieId })
            .then(() => {
                console.log('Favorite status updated successfully.');

                this.movie.Is_Favorited__c = !this.movie.Is_Favorited__c;
                console.log("Movie is favorited: " + this.movie.Is_Favorited__c);
                this.favoriteName = this.movie.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt';
                console.log("Movie favoriteName: " + this.favoriteName);

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

                console.log("Movie ");
                this.movie.Is_In_Watch_List__c = !this.movie.Is_In_Watch_List__c;
                console.log("Movie is in watch list: " + movie.Is_In_Watch_List__c);
                this.toWatchName = this.movie.Is_In_Watch_List__c ? 'utility:check' : 'utility:clock';
                console.log("Movie  toWatchName: " + this.toWatchName);

            })
            .catch(error => {
                console.error('Error updating favorite status: ', error);
            });
    }

    getMovieCast() {
             if (!this.movieId) {
                 console.error('Movie ID is undefined for movie: ', this.movie);
                 return;
             }

             fetch(`https://api.themoviedb.org/3/movie/${this.movieId}/credits?language=en-US`, options)
                 .then(response => response.json())
                 .then(data => {
                     this.movie = { ...this.movie, castInfo: data.cast.map(member => ({
                                         name: member.name,
                                         character: member.character,
                                         profile_path: member.profile_path ? `https://media.themoviedb.org/t/p/w276_and_h350_face${member.profile_path}` : NO_AVATAR_IMAGE
                                     })) };
                     console.log(`Cast Info for movie ID ${this.movieId}:`, this.movie.castInfo);
                 })
                 .catch(err => {
                     console.error(`Error fetching cast for movie ID ${this.movieId}:`, err);
                 });
        }

    handleCommentChange(event) {
        this.comment = event.target.value;
    }

    submitComment() {
        console.log('content comment: ' + this.comment);
        console.log('Movie Id in submit comment ' + this.movieId);

        if (this.comment) {
            saveCommentToMovie({ content: this.comment, movieId: this.movieId })
                .then((result) => {
                    console.log('result ', result);
                    if (result == false) {
                        this.showErrorMessage('You have already commented on this movie.');
                    } else {
                        console.log('Comment saved successfully');
                        this.comment = '';
                        this.loadMovieComments();
                    }

                })
                .catch(error => {
                    console.error('Error saving comment', error);
                });
        }
    }

    loadMovieComments() {
        console.log('Movie Id while loading comments ' + this.movieId);

        getMovieComments({ movieId: this.movieId })
            .then(result => {
                console.log('Comments loaded succesfully ', result);
                this.comments = result;
                const currentUserId = // get current user id from your method or use existing method
                this.hasUserCommented = result.some(comment => comment.CreatedById === currentUserId);
            })
            .catch(error => {
                console.error('Error loading comments', error);
            });


    }

    showErrorMessage(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    clearComment() {
        this.comment = '';
    }

    get isCleanable() {
        return this.isBlank(this.comment);
    }
    isBlank(str) {
        return (!str || /^\s*$/.test(str));
    }
}