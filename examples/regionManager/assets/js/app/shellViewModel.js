/// <reference path="app.js" />
/// <reference path="../lib/knockout.js" />

bo.regionManagerExample.ShellViewModel = function (fullName, email, userType) {
    this.fullName = fullName;
    this.email = email;
    this.userType = userType;
};