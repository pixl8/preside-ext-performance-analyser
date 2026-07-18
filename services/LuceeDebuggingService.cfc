/**
 * @presideService true
 * @singleton      true
 */
component {

	property name="adminApi"           inject="luceeAdminApiWrapper";
	property name="reqLogDao"          inject="presidecms:object:perfanalyser_req_log";
	property name="queryDao"           inject="presidecms:object:perfanalyser_req_log_query";
	property name="execTimeDao"        inject="presidecms:object:perfanalyser_req_log_exec";
	property name="sqlRunner"          inject="sqlRunner";
	property name="luceeDebugFeatures" inject="coldbox:setting:enum.luceeDebugFeatures";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

	public function getDebugSettings() {
		var settings  = adminApi.call( "getDebug" );
		var sysConfig = $getPresideCategorySettings( "performanceAnalyserDebug" );

		settings.templateSettings = getDebugTemplate();
		settings.storageduration  = Val( sysConfig.storageduration ?: 1 );
		settings.includetasks     = $helpers.isTrue( sysConfig.includetasks ?: "" );
		settings.onlyforips       = sysConfig.onlyforips  ?: "";
		settings.onlyforurls      = sysConfig.onlyforurls ?: "";
		settings.excludeurls      = sysConfig.excludeurls ?: "";

		if ( StructKeyExists( sysConfig, "enabled" ) && Len( sysConfig.enabled ) ) {
			settings.debug = $helpers.isTrue( sysConfig.enabled );
		} else {
			settings.debug = _anyDebugFeatureEnabled( settings );
		}

		if ( StructKeyExists( sysConfig, "showlogs" ) && Len( sysConfig.showlogs ) ) {
			settings.showlogs = $helpers.isTrue( sysConfig.showlogs );
		} else if ( _supportsMonitoringApi() ) {
			try {
				var monitoring = adminApi.call( "getMonitoring" );
				settings.showlogs = $helpers.isTrue( monitoring.debug ?: "" );
			} catch ( any e ) {
				settings.showlogs = ( settings.templateSettings.type ?: "" ) == "performance-analyser-display";
			}
		} else {
			settings.showlogs = ( settings.templateSettings.type ?: "" ) == "performance-analyser-display";
		}

		return settings;
	}

	public boolean function isDebugLoggingEnabled() {
		return $helpers.isTrue( $getPresideSetting( "performanceAnalyserDebug", "enabled" ) );
	}

	public boolean function shouldShowDebugOutput() {
		return isDebugLoggingEnabled() && $helpers.isTrue( $getPresideSetting( "performanceAnalyserDebug", "showlogs" ) );
	}

	public void function applyRequestMonitoringOutput() {
		if ( !_supportsMonitoringApi() ) {
			return;
		}

		try {
			application action="update" showDebug=shouldShowDebugOutput();
		} catch ( any e ) {
			// ignore — host may not allow mid-request monitoring updates
		}
	}

	public function saveDebugSettings(
		  required boolean debug
		, required array   features
		, required boolean showlogs
		, required string  ipaddresses
		, required numeric storageduration
		, required boolean includetasks
		, required string  onlyforips
		, required string  onlyforurls
		, required string  excludeurls
	) {
		var debugSettings = { debug=arguments.debug, debugTemplate="" };

		for( var feature in luceeDebugFeatures ) {
			debugSettings[ feature ] = arguments.debug && ArrayFindNoCase( arguments.features, feature ) > 0;
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
			// Empty (silent) logging must apply to all clients. Restricting to the
			// request IP at save-time (often a Docker/proxy address) prevents
			// Lucee from collecting debug data for real browser traffic.
			var ipRange = arguments.showlogs ? Trim( arguments.ipAddresses ) : "*";
			if ( !Len( ipRange ) ) {
				ipRange = "*";
			}

			adminApi.call(
				  action    = "updateDebugEntry"
				, label     = "performanceAnalyserTemplate"
				, debugtype = debugHandler.getId()
				, iprange   = ipRange
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

		adminApi.call( action="updateDebugSetting", maxLogs=0 );
		adminApi.call( action="updateDebug", argumentCollection=debugSettings );

		if ( _supportsMonitoringApi() ) {
			try {
				adminApi.call(
					  action = "updateMonitoring"
					, debug  = arguments.debug && arguments.showlogs
				);
			} catch ( any e ) {
				// older Lucee without monitoring API
			}
		}

		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="enabled"        , value=arguments.debug );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="showlogs"       , value=arguments.showlogs );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="storageduration", value=arguments.storageduration );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="includetasks"   , value=arguments.includetasks );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="onlyforips"     , value=arguments.onlyforips );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="onlyforurls"    , value=arguments.onlyforurls );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="excludeurls"    , value=arguments.excludeurls );
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

	public struct function getDebugLogDetail( required string logId ) {
		if ( !Len( Trim( arguments.logId ) ) || !IsNumeric( arguments.logId ) ) {
			return {};
		}

		var logQuery = reqLogDao.selectData(
			  id           = arguments.logId
			, selectFields = [
				  "id"
				, "type"
				, "url"
				, "total_time"
				, "query_time"
				, "web_user"
				, "admin_user"
				, "datecreated"
			  ]
		);

		if ( !logQuery.recordCount ) {
			return {};
		}

		var detail = {
			  id          = logQuery.id
			, type        = logQuery.type
			, url         = logQuery.url
			, total_time  = logQuery.total_time
			, query_time  = logQuery.query_time
			, web_user    = logQuery.web_user
			, admin_user  = logQuery.admin_user
			, datecreated = logQuery.datecreated
			, queries     = queryDao.selectData(
				  filter  = { req=arguments.logId }
				, orderBy = "exec_time desc"
			  )
			, execs       = execTimeDao.selectData(
				  filter  = { req=arguments.logId }
				, orderBy = "total_time desc"
			  )
		};

		detail.query_count = detail.queries.recordCount;

		return detail;
	}

	public void function log(
		  pageUrl   = "/"
		, adminuser = ""
		, webuser   = ""
		, type      = "http"
	) {
		if ( !isDebugLoggingEnabled() || !_shouldLogRequest( type=arguments.type, pageUrl=arguments.pageUrl ) ) {
			return;
		}

		var pc        = getPageContext();
		var debugger  = pc.getDebugger();
		var debugData = debugger.getDebuggingData( pc, true );

		var logData = {
			  type       = arguments.type
			, url        = arguments.pageUrl
			, url_hash   = Hash( arguments.pageUrl )
			, total_time = Val( debugData.times.total ?: "" )
			, query_time = Val( debugData.times.query ?: "" )
		};

		if ( Len( arguments.webuser ) ) {
			logData.web_user = arguments.webuser;
		}
		if ( Len( arguments.adminuser ) ) {
			logData.admin_user = arguments.adminuser;
		}

		var logId = reqLogDao.insertData( logData );

		_logQueries( logId, debugData.queries ?: [] );
		_logExecutionTimes( logId, debugData.pages ?: [] );
	}

	public boolean function cleanupOldLogs( logger ) {
		var canLog     = StructKeyExists( arguments, "logger" );
		var canInfo    = canLog && arguments.logger.canInfo();
		var maxStorage = Val( $getPresideSetting( "performanceAnalyserDebug", "storageduration" ) );

		if ( maxStorage < 1 ) {
			maxStorage = 1;
		}

		var deleted = reqLogDao.deleteData( filter="datecreated <= :datecreated", filterParams={ datecreated=DateAdd( "d", 0-maxStorage, Now() ) } );

		if ( canInfo ) {
			arguments.logger.info( "[#NumberFormat( deleted )#] debug log(s) older than [#NumberFormat( maxStorage )#] day(s) were deleted from the system." );
		}

		return true;
	}

// helpers
	private boolean function _supportsMonitoringApi() {
		var version = server.lucee.version ?: "0";
		return Val( ListFirst( version, "." ) ) > 6 || ( Val( ListFirst( version, "." ) ) == 6 && Val( ListGetAt( version, 2, "." ) ) >= 1 );
	}

	private boolean function _anyDebugFeatureEnabled( required struct settings ) {
		for( var feature in luceeDebugFeatures ) {
			if ( $helpers.isTrue( arguments.settings[ feature ] ?: "" ) ) {
				return true;
			}
		}
		return false;
	}

	private function _logQueries( logId, queries ) {
		var params = [];
		var counter = 0;

		for( var q in arguments.queries ) {
			ArrayAppend( params, { type="cf_sql_bigint" , value=arguments.logId });
			ArrayAppend( params, { type="cf_sql_text"   , value=q.sql           });
			ArrayAppend( params, { type="cf_sql_varchar", value=Hash( q.sql )   });
			ArrayAppend( params, { type="cf_sql_bigint" , value=q.time          });
			ArrayAppend( params, { type="cf_sql_int"    , value=q.count         });

			if ( ++counter == 100 ) {
				sqlRunner.runSql( dsn=queryDao.getDsn(), sql=_getInsertQueriesSql( counter ), params=params );
				counter = 0;
				params  = [];
			}
		}

		if ( counter > 0 ) {
			sqlRunner.runSql( dsn=queryDao.getDsn(), sql=_getInsertQueriesSql( counter ), params=params );
		}
	}

	private function _logExecutionTimes( logId, pages ) {
		var params = [];
		var counter = 0;

		for( var p in arguments.pages ) {
			var templatePath = Left( ListFirst( p.src, "$" ), 255 )
			var methodName   = ListLen( p.src, "$" ) > 1 ? Left( ListRest( p.src, "$" ), 255 ) : "-";

			ArrayAppend( params, { type="cf_sql_bigint" , value=arguments.logId                      });
			ArrayAppend( params, { type="cf_sql_varchar", value=templatePath                         });
			ArrayAppend( params, { type="cf_sql_varchar", value=methodName                           });
			ArrayAppend( params, { type="cf_sql_int"    , value=p.count                              });
			ArrayAppend( params, { type="cf_sql_bigint" , value=p.min                                });
			ArrayAppend( params, { type="cf_sql_bigint" , value=p.max                                });
			ArrayAppend( params, { type="cf_sql_bigint" , value=p.avg                                });
			ArrayAppend( params, { type="cf_sql_bigint" , value=p.total                              });
			ArrayAppend( params, { type="cf_sql_bigint" , value=p.load                               });

			if ( ++counter == 100 ) {
				sqlRunner.runSql( dsn=queryDao.getDsn(), sql=_getInsertExecTimesSql( counter ), params=params );
				counter = 0;
				params  = [];
			}
		}

		if ( counter > 0 ) {
			sqlRunner.runSql( dsn=queryDao.getDsn(), sql=_getInsertExecTimesSql( counter ), params=params );
		}
	}

	private function _getInsertQueriesSql( rows ) {
		if ( !StructKeyExists( variables, "_insertQueriesHeader" ) ) {
			var adapter = queryDao.getDbAdapter();
			var insertSql = adapter.getInsertSql( queryDao.getTableName(), [ "req", "sql", "sql_hash", "exec_time", "recordcount" ] );

			variables._insertQueriesHeader = ReReplace( insertSql[ 1 ], "values \(.*$", "values (?,?,?,?,?)" );
		}

		return variables._insertQueriesHeader & RepeatString( ", (?,?,?,?,?)", arguments.rows-1 );
	}
	private function _getInsertExecTimesSql( rows ) {
		if ( !StructKeyExists( variables, "_insertExecTimesHeader" ) ) {
			var adapter = execTimeDao.getDbAdapter();
			var insertSql = adapter.getInsertSql( execTimeDao.getTableName(), [ "req", "template_path", "method_name", "call_count", "min_time", "max_time", "mean_time", "total_time", "load" ] );

			variables._insertExecTimesHeader = ReReplace( insertSql[ 1 ], "values \(.*$", "values (?,?,?,?,?,?,?,?,?)" );
		}

		return variables._insertExecTimesHeader & RepeatString( ", (?,?,?,?,?,?,?,?,?)", arguments.rows-1 );
	}

	private function _shouldLogRequest( type, pageurl ) {
		var shouldLog = true;
		var settings  = $getPresideCategorySettings( "performanceAnalyserDebug" );
		var event     = $getRequestContext();

		if ( arguments.type == "task" || arguments.type == "adhoctask" ) {
			return $helpers.isTrue( settings.includetasks ?: "" );
		}

		if ( Len( Trim( settings.onlyforips ?: "" ) ) ) {
			shouldLog = false;

			var clientIp = event.getClientIp();
			for( var ip in ListToArray( settings.onlyforips, Chr( 10 ) & Chr( 13 ) ) ) {
				ip = Trim( ip );
				if ( Len( ip ) && ip == clientIp ) {
					shouldLog = true;
					break;
				}
			}
		}

		if ( shouldLog && Len( Trim( settings.onlyforurls ?: "" ) ) ) {
			shouldLog = false;

			var currentUrl = Len( arguments.pageurl ) ? arguments.pageurl : event.getCurrentUrl( includeQueryString=false );
			for( var urlPattern in ListToArray( settings.onlyforurls, Chr( 10 ) & Chr( 13 ) ) ) {
				urlPattern = Trim( urlPattern );
				if ( Len( urlPattern ) && ReFindNoCase( urlPattern, currentUrl ) ) {
					shouldLog = true;
					break;
				}
			}
		}

		if ( shouldLog && Len( Trim( settings.excludeurls ?: "" ) ) ) {
			var currentUrl = Len( arguments.pageurl ) ? arguments.pageurl : event.getCurrentUrl( includeQueryString=false );
			for( var urlPattern in ListToArray( settings.excludeurls, Chr( 10 ) & Chr( 13 ) ) ) {
				urlPattern = Trim( urlPattern );
				if ( Len( urlPattern ) && ReFindNoCase( urlPattern, currentUrl ) ) {
					shouldLog = false;
					break;
				}
			}
		}

		return shouldLog;
	}

}
