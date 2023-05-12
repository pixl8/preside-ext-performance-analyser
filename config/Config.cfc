component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupPermissions( settings );
		_setupNavigation( settings );
	}

	private void function _setupPermissions( settings ) {
		settings.adminPermissions = settings.adminPermissions ?: {};

		settings.adminPermissions.performanceanalyser = [ "access" ];
		// deliberately no role defined. Super users only by default
	}

	private void function _setupNavigation( settings ) {
		settings.adminConfigurationMenuItems = settings.adminConfigurationMenuItems ?: [];

		ArrayAppend( settings.adminConfigurationMenuItems, "presidePerformanceAnalyser" );
		settings.adminMenuItems.presidePerformanceAnalyser = {
			  permissionKey = "performanceanalyser.access"
			, buildLinkArgs = { linkTo="performanceanalyser" }
			, activeChecks  = { handlerPatterns="^admin\.performanceanalyser" }
		};
	}
}
