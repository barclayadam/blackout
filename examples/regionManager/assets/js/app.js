/// <reference path="../lib/jquery.js" />
/// <reference path="../lib/knockout.js" />
/// <reference path="../lib/blackout.js" />
/// <reference path="sitemap.js" />
/// <reference path="~/commands.js" />

function App(shellModel) {
    this.shell = new bo.regionManagerExample.ShellViewModel(shellModel.fullName, shellModel.email, shellModel.userType);
    this.regionManager = new bo.RegionManager();
    this.sitemap = new bo.regionManagerExample.Sitemap(this.regionManager);
};

bo.exportSymbol('bo.regionManagerExample.App.start', function (shellModel) {
    bo.exportSymbol('bo.regionManagerExample.App', new App(shellModel));
    ko.applyBindings(bo.regionManagerExample.App);

    bo.bus.publish('appInitialised');
    bo.bus.publish('navigateToRoute:Home');
});
