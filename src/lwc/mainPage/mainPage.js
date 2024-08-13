/**
 * Created by mateusz.jurkowicz_br on 01.08.2024.
 */

import { LightningElement, track } from 'lwc';

export default class MainPage extends LightningElement {

    activeTab = 'Movies';
    activeDropdownItem = 'Popular movies';

    connectedCallback() {
        console.log('connectedCallback');
    }

//    get activeTab() {
//        return this._activeTab;
//    }
//
//    set activeTab(value) {
//        console.log(`activeTab = ${value}`);
//        this._activeTab = value;
//    }

//    handleMovieTabChange(event) {
//        console.log('handleMovieTabChange');
//        console.log(event.target);
//        console.log(event.currentTarget);
//        if(event.currentTarget.title) {
//                 const tabTitle = event.currentTarget.title;
//                 this.activeTab = tabTitle;
//        }
//
//         console.log('Active Tab: ', this.activeTab);
//    }
//    handleActorTabChange(event) {
//
//         const tabTitle = event.currentTarget.title;
//         this.activeTab = tabTitle;
//         console.log('Active Tab: ', this.activeTab);
//    }

    handleTabChange(event) {
        debugger;
        const tabTitle = event.currentTarget.title;
        this.activeTab = tabTitle;
        console.log('Active Tab: ', this.activeTab);
//        this.updateActiveClass();
    }

    toggleMenu(event) {
        const dropdownTrigger = event.currentTarget.closest('.slds-dropdown-trigger');
        dropdownTrigger.classList.toggle('slds-is-open');
    }

    handleDropdownSelect(event) {
        console.log('handleDropdownSelect');
        event.stopPropagation();
        const selectedValue = event.currentTarget.dataset.value;
        this.activeDropdownItem = selectedValue;
        this.toggleMenu(event);
        console.log('Selected Dropdown Item: ', this.activeDropdownItem);
        this.updateActiveClass();
    }

    handleSearch(event) {
        const searchTerm = event.target.value;

        // Jeśli aktywna jest zakładka Movies
        if (this.isMoviesTabActive) {
            // Sprawdzamy, czy aktywny jest komponent Popular
            if (this.isPopularFilmsActive) {
                const popularFilmsComponent = this.template.querySelector('c-movies-page');
                if (popularFilmsComponent) {
                    popularFilmsComponent.handleSearch(searchTerm);
                    console.log('Szukano w Popular na Movies Page:', searchTerm);
                }
            }
            // Sprawdzamy, czy aktywny jest komponent Top Rated
            else if (this.isTopRatedFilmsActive) {
                const topRatedFilmsComponent = this.template.querySelector('c-movies-page');
                if (topRatedFilmsComponent) {
                    topRatedFilmsComponent.handleSearch(searchTerm);
                    console.log('Szukano w Top Rated na Movies Page:', searchTerm);
                }
            }
            else if (this.isFavoriteFilmsActive) {
                const favoriteFilmsComponent = this.template.querySelector('c-movies-page');
                if (favoriteFilmsComponent) {
                    favoriteFilmsComponent.handleSearch(searchTerm);
                    console.log('Szukano w Favorite na Movies Page:', searchTerm);
                }
            }
            else if (this.isWatchFilmsActive) {
                const watchFilmsComponent = this.template.querySelector('c-movies-page');
                if (watchFilmsComponent) {
                    watchFilmsComponent.handleSearch(searchTerm);
                    console.log('Szukano w Watch na Movies Page:', searchTerm);
                }
            }
        } else {
            if (this.isPopularActorsActive) {
                const popularActorsComponent = this.template.querySelector('c-persons-page');
                if (popularActorsComponent) {
                    popularActorsComponent.handleSearch(searchTerm);
                    console.log(popularActorsComponent);
                    console.log('Szukano w Popular na Persons Page:', searchTerm);
                }
            }
            else if (this.isFavoriteActorsActive) {
                const isFavoriteActorsComponent = this.template.querySelector('c-persons-page');
                if (isFavoriteActorsComponent) {
                    isFavoriteActorsComponent.handleSearch(searchTerm);
                    console.log('Szukano w Favorites na Persons Page:', searchTerm);
                }
            }
        }
    }

    updateActiveClass() { //podswietla taby
        const tabs = this.template.querySelectorAll('.slds-tabs_default__item');

        tabs.forEach(tab => {
            if (tab.dataset.tab === this.activeTab) {
                tab.classList.add('slds-is-active');
            } else {
                tab.classList.remove('slds-is-active');
            }
        });
    }

    get isMoviesTabActive() {
        return this.activeTab === 'Movies';
    }
    get isActorsTabActive() {
        return this.activeTab === 'Actors';
    }

    get isPopularFilmsActive() {
        return this.activeDropdownItem === 'Popular movies';
    }
    get isTopRatedFilmsActive() {
        return this.activeDropdownItem === 'Top rated movies';
    }
    get isFavoriteFilmsActive() {
        return this.activeDropdownItem === 'Favorite movies';
    }
    get isWatchFilmsActive() {
        return this.activeDropdownItem === 'To watch movies';
    }
    get isPopularActorsActive() {
        return this.activeDropdownItem === 'Popular actors';
    }
    get isFavoriteActorsActive() {
        return this.activeDropdownItem === 'Favorite actors';
    }
}