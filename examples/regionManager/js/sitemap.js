/// <reference path="../lib/blackout.js" />

(function () {
    bo.exportSymbol('bo.regionManagerExample.Sitemap', function (regionManager) {
        return new bo.Sitemap(regionManager, {
            'Home': {
                url: '/',
                parts: [new bo.Part('Home', {
                    templateName: 'home'
                })]
            },

            'Error': {
                url: '/Error',
                parts: [new bo.Part('Error')],

                isInNavigation: false
            },

            'Manage Users': {
                'Users List': {
                    url: '/ManageUsers/UsersList',
                    parts: [new bo.Part("Manage Users/Users List", {
                        region: 'main',
                        templateName: 'usersList',
                        viewModel: bo.regionManagerExample.UsersListViewModel
                    })]
                }
            }
        });
    });
} ());
