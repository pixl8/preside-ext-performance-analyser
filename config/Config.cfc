component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupPermissions( settings );
		_setupNavigation( settings );
		_setupExtensionSettings( settings );
		_setupEnums( settings );
		_setupInterceptors( conf );
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

	private void function _setupExtensionSettings( settings ) {
		settings.performanceAnalyser = settings.performanceAnalyser ?: {};

		settings.performanceAnalyser.luceeAdminPassword = settings.performanceAnalyser.luceeAdminPassword ?: ( settings.env.LUCEE_ADMIN_PASSWORD ?: "" );
	}

	private void function _setupEnums( settings ) {
		settings.enum.luceeDebugFeatures = [ "database", "queryusage", "dump", "exception", "timer", "tracing" ];
	}

	private void function _setupInterceptors( config ) {
		ArrayAppend( config.interceptors, { class="app.extensions.preside-ext-performance-analyser.interceptors.PerformanceAnalyserInterceptor", properties={} } );
	}
}
