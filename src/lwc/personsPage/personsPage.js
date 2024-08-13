/**
 * Created by mateusz.jurkowicz_br on 01.08.2024.
 */

import { LightningElement, track, api } from 'lwc';
import loadAllPersons from '@salesforce/apex/PersonsDetailsController.loadAllPersons';
import {NavigationMixin} from 'lightning/navigation';
import NO_AVATAR_IMAGE from "@salesforce/resourceUrl/no_avatar";
import changeFavoriteStatus from '@salesforce/apex/PersonsDetailsController.changeFavoriteStatus';

const options = {
    method: 'GET',
    headers: {
        accept: 'application/json',
        Authorization: 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjJjYjcxOTgwMWQyNmJlMTZjYTg1NGJiYWQ5YjViYSIsIm5iZiI6MTcyMzAyMDE5Ny44ODg3NTEsInN1YiI6IjY2YWIzZGZhYWZkZjVjM2Y5N2QyYzY5MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.-IbNV34APBJfZRMNMCXOu9OoHu07Qy8EjMOdl92fONU'
    }
};

export default class PersonsPage extends NavigationMixin(LightningElement) {
    @api name;
    @track persons = [];
    @track searchKey = '';
    isLoading = false;

    connectedCallback() {
        this.fetchPersonsData();
        console.log('NAME ' + this.name);
        this.template.addEventListener('search', this.handleSearch.bind(this));
    }


    fetchPersonsData() {
        this.isLoading = true;
//        debugger;
        loadAllPersons({ name: this.name, searchKey: this.searchKey})
            .then(result => {
                console.log('Persons data: ', result);
                this.persons = result.map(person => {
                     return Object.assign({}, person, {
                         favoriteName: person.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt',
                     });
                });
                console.log('Persons loaded successfully');
            })
            .catch(error => {
                this.persons = null;
                console.error('Error loading persons', error);
            })
            .finally(() => {
                this.isLoading = false;
            })
    }


    navigateToPersonDetailPage(event) {

        debugger;

        event.preventDefault();
        console.log(event.currentTarget);
        const personId = event.currentTarget.dataset.id;
        console.log('Person ID ' + personId);

        this[NavigationMixin.Navigate]({

            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Person_Detail_Page',
            },
            state: {
                c__personId: personId,
            },
        });
    }
    
    favoriteClick(event) {
        event.preventDefault();
        const personId = event.target.dataset.id;
        console.log('Person ID FAVORITE ' + personId);
    
        changeFavoriteStatus({ personId: personId })
            .then(() => {
                console.log('Favorite status updated successfully.');
    
                let person = this.persons.find(person => person.Actor_id__c == personId);
                if (person) {
                    console.log("Person ");
                    person.Is_Favorited__c = !person.Is_Favorited__c;
                    console.log("Person is favorited: " + person.Is_Favorited__c);
                    person.favoriteName = person.Is_Favorited__c ? 'utility:favorite' : 'utility:favorite_alt';
                    console.log("Person favoriteName: " + person.favoriteName);
                }
    
            })
            .catch(error => {
                console.error('Error updating favorite status: ', error);
            });
    }


    @api
    handleSearch(searchTerm) {
        this.searchKey = searchTerm;
        this.fetchPersonsData();
        console.log('MOVIES SEARCHING ', searchTerm);
    }
}