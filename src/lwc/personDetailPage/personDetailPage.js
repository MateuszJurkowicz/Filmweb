import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getPersonDetails from '@salesforce/apex/PersonsDetailsController.getPersonDetails';
import changeFavoriteStatus from '@salesforce/apex/PersonsDetailsController.changeFavoriteStatus';
import NO_AVATAR_IMAGE from "@salesforce/resourceUrl/no_avatar";

const options = {
    method: 'GET',
    headers: {
        accept: 'application/json',
        Authorization: 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMzAyMDE5Ny44ODg3NTEsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.-IbNV34APBJfZRMNMCXOu9OoHu07Qy8EjMOdl92fONU'
    }
};


export default class PersonDetailPage extends NavigationMixin(LightningElement) {
    personId;
    linkName = '';
    iconName = '';

    @track person;
    @track comment;
    @track comments = [];

    @wire(CurrentPageReference)
    pageRef(data) {
        console.log(JSON.stringify(data));
        this.personId = data.state.c__personId;
        this.loadPersonDetails();
    }

    connectedCallback() {
        this.loadPersonDetails();
    }

    loadPersonDetails() {
        getPersonDetails({ personId: this.personId })
            .then(result => {
                debugger;
                this.person = result;
                this.linkName = this.person.Biography__c.length > 200 ? 'View more' : '';
                this.iconName = this.person.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt';
                this.getActorFilms();
                console.log('Person details loaded successfully: ', result);
            })
            .catch(error => {
                this.person = null;
                console.error('Error loading person details', error);
            });
    }

    getActorFilms() {
         if (!this.person.Actor_id__c) {
             console.error('Person ID is undefined for person:', this.person);
             return;
         }

         fetch(`https://api.themoviedb.org/3/person/${this.person.Actor_id__c}/combined_credits?language=en-US`, options)
             .then(response => response.json())
             .then(data => {
                 this.person = {
                     ...this.person, // kopiowanie istniejących właściwości
                     filmsInfo: data.cast.map(member => ({
                         title: member.title,
                         character: member.character,
                         poster_path: member.poster_path ? `https://media.themoviedb.org/t/p/w300_and_h450_bestv2${member.poster_path}` : NO_AVATAR_IMAGE
                     }))
                 };
                 console.log(`Films Info for person ID ${this.person.Actor_id__c}:`, this.person.filmsInfo);
             })
             .catch(err => {
                 console.error(`Error fetching cast for person ID ${this.person.Actor_id__c}:`, err);
             });
    }

    viewMore() {
        console.log('LINK NAME PERSON: ' + this.linkName);
        if (this.linkName == 'View more') {
             this.template.querySelector('.content').classList.remove('slds-line-clamp_medium');
             this.linkName = 'View less';
        } else {
             this.template.querySelector('.content').classList.add('slds-line-clamp_medium');
             this.linkName = 'View more';
        }
    }

    favoriteClick() {
        changeFavoriteStatus({ personId: this.Actor_id__c })
            .then(() => {
                console.log('Favorite status updated successfully.');

                    console.log("Person ");
                    this.person.Is_Favorited__c = !this.person.Is_Favorited__c;
                    console.log("Person is favorited: " + this.person.Is_Favorited__c);
                    this.iconName = this.person.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt';
                    console.log("Person favoriteName: " + this.iconName);

            })
            .catch(error => {
                console.error('Error updating favorite status: ', error);
            });
    }
}