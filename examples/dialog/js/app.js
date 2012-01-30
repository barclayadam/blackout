/// <reference path="../lib/jquery.js" />
/// <reference path="../lib/knockout.js" />
/// <reference path="../lib/blackout.js" />
/// <reference path="sitemap.js" />
/// <reference path="~/commands.js" />

(function (undefined) {
    function User(values, listViewModel) {
        this.userId = values.userId;
        this.name = values.name;
        this.username = values.username;
        this.isActive = ko.observable(values.isActive);

        this.select = function () {
            listViewModel.selectedUser(this);
        };

        this.isSelected = ko.computed(function () {
            return listViewModel.selectedUser() == this;
        }, this);
    }

    var UsersListViewModel = bo.ViewModel.subclass(function () {
        this.selectedUser = ko.observable();
        this.users = ko.observableArray([new User({ userId: 0, name: "Test", username: "Test", isActive: true }, this)]);
    });

    _.extend(UsersListViewModel.prototype, {
        show: function() {
            var deferred = new jQuery.Deferred();
            setTimeout(deferred.resolve, 250);            
            return deferred.promise();
        },

        getDialogOptions: function() {
            return {
                title: 'User List'
            };
        }
    });

    bo.exportSymbol('bo.dialogExample.UsersListViewModel', UsersListViewModel);
} ());

function App() {
};

App.prototype.showUsers = function() {
	new bo.Dialog(
        new bo.Part('Users List', 
                    { templateName: 'usersList',
                      viewModel: new bo.dialogExample.UsersListViewModel()
                    })
    ).show();
}

bo.exportSymbol('bo.dialogExample.App.start', function () {
    ko.applyBindings(new App());
});
