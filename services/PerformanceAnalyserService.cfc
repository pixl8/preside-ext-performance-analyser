/**
 * @presideService true
 * @singleton      true
 */
component {

	property name="adminApi" inject="luceeAdminApiWrapper";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

	public function getDebugSettings() {
		var settings = adminApi.call( "getDebug" );

		settings.maxLogs          = getMaxLogs();
		settings.templateSettings = getDebugTemplate();

		return settings;
	}

	public function saveDebugSettings(
		  required boolean debug
		, required numeric maxlogs
		, required array   features
		, required boolean showlogs
		, required string  ipaddresses
	) {
		var debugSettings = { debug=arguments.debug, debugTemplate="" };
		for( var feature in arguments.features ) {
			debugSettings[ feature ] = true;
		}

		if ( arguments.debug ) {
			var debugHandler     = CreateObject( "app.extensions.preside-ext-performance-analyser.debugtemplates.#( arguments.showlogs ? 'Display' : 'Empty' )#" );
			var debugHandlerMeta = GetMetaData( debugHandler );
			var custom           = arguments.showlogs ? {
				  color     = "black"
				, bgcolor   = "white"
				, minimal   = 0
				, highlight = 2500
				, general   = true
				, scopes    = "Application,CGI,Client,Cookie,Form,Request,Server,Session,URL"
			} : {};

			adminApi.call(
				  action    = "updateDebugEntry"
				, label     = "performanceAnalyserTemplate"
				, debugtype = debugHandler.getId()
				, iprange   = arguments.ipAddresses
				, fullname  = debugHandlerMeta.fullname
				, path      = ContractPath( debugHandlerMeta.path )
				, custom    = custom
			);

			debugSettings.debugTemplate = "performanceAnalyserTemplate";
		} else {
			var currentTemplate = getDebugTemplate();

			if ( Len( currentTemplate.id ?: "" ) ) {
				adminApi.call( action="removeDebugEntry", id=currentTemplate.id );
			}
		}

		adminApi.call( action="updateDebugSetting", maxLogs=arguments.maxLogs );
		adminApi.call( action="updateDebug", argumentCollection=debugSettings );
	}

	public function getRawDebugLogs(){
		return adminApi.call( "getLoggedDebugData" );
	}

	public function getDebugTemplate() {
		var templates = adminApi.call( "getDebugEntry" );
		for( var template in templates ) {
			if ( template.label == "performanceAnalyserTemplate" ) {
				return template;
			}
		}
		return {};
	}

	public function getMaxLogs() {
		return Val( adminApi.call( "getDebugSetting" ).maxLogs ?: "" );
	}

}