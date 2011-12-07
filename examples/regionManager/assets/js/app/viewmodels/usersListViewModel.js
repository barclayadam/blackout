/// <reference path="../app.js" />
/// <reference path="../../lib/underscore.js" />
/// <reference path="../../lib/knockout.js" />

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

    bo.regionManagerExample.UsersListViewModel = bo.ViewModel.subclass(function () {
        this.selectedUser = ko.observable();
        this.users = ko.observableArray([new User({ userId: 0, name: "Test", username: "Test", isActive: true }, this)]);
    });

    _.extend(bo.regionManagerExample.UsersListViewModel.prototype, {
        show: function() {
            var deferred = new jQuery.Deferred();
            setTimeout(deferred.resolve, 1500);
            return deferred.promise();
        }
    });
} ());