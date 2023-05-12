component extends="preside.system.base.AdminHandler" {

	public void function index() {
		prc.pageIcon = "fa-bolt";
		prc.pageTitle = translateResource( "performanceanalyser:admin.homepage.title" );

		event.addAdminBreadCrumb( title=translateResource( "performanceanalyser:admin.homepage.breadcrumb" ), link="" )
	}

}