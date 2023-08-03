component extends="preside.system.base.AdminHandler" {

	property name="performanceAnalyserService" inject="performanceAnalyserService";
	property name="luceeAdminApiWrapper"       inject="luceeAdminApiWrapper";
	property name="heapDumpService"            inject="heapDumpService";
	property name="luceeDebugFeatures"         inject="coldbox:setting:enum.luceeDebugFeatures";

	function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection=arguments );

		if ( !hasCmsPermission( "performanceanalyser.access" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb( title=translateResource( "performanceanalyser:admin.homepage.breadcrumb" ), link=event.buildAdminLink( linkto="performanceanalyser" ) );
		prc.pageIcon = "fa-bolt";
		prc.canControlAdmin = luceeAdminApiWrapper.canConnect();
	}

// PUBLIC ACTIONS
	public void function index() {
		prc.pageTitle = translateResource( "performanceanalyser:admin.homepage.title" );

		prc.tabs = [ "debugger", "threads", "heapdumps" ];
		prc.tab = rc.tab ?: "";

		if ( !ArrayFindNoCase( prc.tabs, prc.tab ) ) {
			prc.tab = prc.tabs[ 1 ];
		}
		prc.tabContent = renderViewlet( event="admin.performanceAnalyser._#prc.tab#Tab" );
		prc.topRightButtons = renderViewlet( "admin.performanceanalyser.topRightButtons" );
	}

	public void function editSettings() {
		if ( !prc.canControlAdmin ) {
			setNextEvent( url=event.buildAdminLink( linkto="performanceanalyser" ) );
		}

		prc.pageTitle = translateResource( "performanceanalyser:edit.settings.page.title" );
		event.addAdminBreadCrumb( title=translateResource( "performanceanalyser:edit.settings.page.breadcrumb" ), link="" );

		var rawSettings = performanceAnalyserService.getDebugSettings();

		prc.debugSettings = {
			  debug       = rawSettings.debug
			, maxlogs     = rawSettings.maxLogs
			, showlogs    = ( rawSettings.templateSettings.type ?: "" ) != "performance-analyser-empty"
			, ipaddresses = ( rawSettings.templateSettings.ipRange ?: cgi.remote_addr )
			, features    = []
		};

		for( var feature in luceeDebugFeatures ) {
			if ( IsTrue( rawSettings[ feature ] ?: "" ) ) {
				ArrayAppend( prc.debugSettings.features, feature );
			}
		}
		prc.debugSettings.features = ArrayToList( prc.debugSettings.features );

		prc.formName   = "performance.analyser.settings";
		prc.postAction = event.buildAdminLink( linkto="performanceanalyser.editSettingsAction" );
		prc.cancelLink = event.buildAdminLink( linkto="performanceanalyser" );
	}

	public void function editSettingsAction() {
		if ( !prc.canControlAdmin ) {
			setNextEvent( url=event.buildAdminLink( linkto="performanceanalyser" ) );
		}

		var formName = "performance.analyser.settings";
		var formData = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			var persist = formData;
			persist.validationResult = validationResult;

			setNextEvent(
				  url           = event.buildAdminLink( linkto="performanceanalyser.editsettings" )
				, persistStruct = persist
			);
		}

		performanceAnalyserService.saveDebugSettings(
			  debug       = isTrue( formData.debug ?: "" )
			, maxlogs     = Val( formData.maxlogs ?: 10 )
			, features    = ListToArray( formData.features ?: "" )
			, showlogs    = isTrue( formData.showlogs ?: "" )
			, ipaddresses = formData.ipaddresses ?: cgi.remote_addr
		);

		event.audit(
			  action   = isTrue( formData.debug ?: "" ) ? "enabledebugging" : "disabledebugging"
			, type     = "performanceanalyser"
			, recordId = "performanceanalyser"
			, detail   = formData
		);

		messageBox.info( translateResource( "performanceanalyser:settings.saved.confirmation" ) );

		setNextEvent( url=event.buildAdminLink( linkto="performanceanalyser" ) );
	}

	public void function takeHeapdumpAction() {
		if ( !prc.canControlAdmin ) {
			event.adminAccessDenied();
		}

		setNextEvent( url=heapDumpService.getHeapDump() );
	}

// PRIVATE VIEWLETS, ETC
	private string function topRightButtons() {
		var buttons = [];

		if ( IsTrue( prc.canControlAdmin ?: "" ) ) {
			ArrayAppend( buttons, {
				  link      = event.buildAdminLink( linkto="performanceanalyser.editsettings" )
				, title     = translateResource( "performanceanalyser:edit.debug.settings.btn" )
				, iconClass = "fa-cogs"
				, btnClass  = "btn-primary"
			} );

			ArrayAppend( buttons, {
				  link      = event.buildAdminLink( linkto="performanceanalyser.takeHeapdumpAction" )
				, title     = translateResource( "performanceanalyser:heap.dump.btn" )
				, iconClass = "fa-download"
				, btnClass  = "btn-secondary"
			} );
		}

		for( var i=1; i<=ArrayLen( buttons ); i++) {
			buttons[ i ] = renderView( view="/admin/datamanager/_topRightButton", args=buttons[ i ] );
		}

		return ArrayToList( buttons, " " );
	}

	private string function _debuggerTab( event, rc, prc, args={} ) {
		if ( prc.canControlAdmin ){
			args.debugSettings    = performanceAnalyserService.getDebugSettings();
			args.debuggingEnabled = isTrue( args.debugSettings.debug ?: "" );
		}

		return renderView( view="/admin/performanceAnalyser/_debuggerTab", args=args );
	}

	private string function _threadsTab() {
		return '<p class="text-center">TODO: something really awesome here!</p>';
	}
}