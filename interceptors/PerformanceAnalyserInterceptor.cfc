component extends="coldbox.system.Interceptor" {

	public void function configure() {}

	public void function preProcess( event ) {
		debugAdd( "custom", { pageUrl=event.getCurrentUrl() } );
	}

	public void function postInitializePresideSiteteePage( event ) {
		debugAdd( "custom", { pageType=event.getCurrentPageType() } );
	}
}
