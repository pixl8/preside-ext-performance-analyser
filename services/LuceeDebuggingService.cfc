/**
 * @presideService true
 * @singleton      true
 */
component {

	property name="adminApi"    inject="luceeAdminApiWrapper";
	property name="reqLogDao"   inject="presidecms:object:perfanalyser_req_log";
	property name="queryDao"    inject="presidecms:object:perfanalyser_req_log_query";
	property name="execTimeDao" inject="presidecms:object:perfanalyser_req_log_exec";
	property name="sqlRunner"   inject="sqlRunner";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

	public function getDebugSettings() {
		var settings = adminApi.call( "getDebug" );

		settings.templateSettings = getDebugTemplate();

		var sysConfig = $getPresideCategorySettings( "performanceAnalyserDebug" );

		settings.storageduration = Val( sysConfig.storageduration ?: 1 );
		settings.includetasks    = $helpers.isTrue( sysConfig.includetasks ?: "" );
		settings.onlyforips      = sysConfig.onlyforips      ?: "";
		settings.onlyforurls     = sysConfig.onlyforurls     ?: "";
		settings.excludeurls     = sysConfig.excludeurls     ?: "";

		return settings;
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

		adminApi.call( action="updateDebugSetting", maxLogs=0 );
		adminApi.call( action="updateDebug", argumentCollection=debugSettings );

		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="storageduration", value=arguments.storageduration );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="includetasks"   , value=arguments.includetasks    );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="onlyforips"     , value=arguments.onlyforips      );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="onlyforurls"    , value=arguments.onlyforurls     );
		$getSystemConfigurationService().saveSetting( category="performanceAnalyserDebug", setting="excludeurls"    , value=arguments.excludeurls     );
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

	public void function log(
		  pageUrl   = "/"
		, adminuser = ""
		, webuser   = ""
		, type      = "http"
	) {
		var pc = getPageContext();
		if ( pc.getConfig().debug() && _shouldLogRequest( type=arguments.type, pageUrl=arguments.pageUrl ) ) {
			var debugger  = pc.getDebugger();
			var debugData = debugger.getDebuggingData( pc, true );

			var logId = reqLogDao.insertData( {
				  type       = arguments.type
				, url        = arguments.pageUrl
				, url_hash   = Hash( arguments.pageUrl )
				, web_user   = arguments.webuser
				, admin_user = arguments.adminUser
				, total_time = Val( debugData.times.total ?: "" )
				, query_time = Val( debugData.times.query ?: "" )
			} );

			_logQueries( logId, debugData.queries );
			_logExecutionTimes( logId, debugData.pages );
		}
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
	private function _logQueries( logId, queries ) {
		var params = [];
		var counter = 0;

		for( var q in arguments.queries ) {
			ArrayAppend( params, { type="cf_sql_bigint" , value=arguments.logId });
			ArrayAppend( params, { type="cf_sql_text"   , value=q.sql           });
			ArrayAppend( params, { type="cf_sql_varchar", value=Hash( q.sql )   });
			ArrayAppend( params, { type="cf_sql_int"    , value=q.time          });
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
			ArrayAppend( params, { type="cf_sql_int"    , value=p.min                                });
			ArrayAppend( params, { type="cf_sql_int"    , value=p.max                                });
			ArrayAppend( params, { type="cf_sql_int"    , value=p.avg                                });
			ArrayAppend( params, { type="cf_sql_int"    , value=p.total                              });
			ArrayAppend( params, { type="cf_sql_int"    , value=p.load                               });

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
			return StructKeyExists( settings, "includetasks" ) && IsBoolean( settings.includetasks ) && settings.includetasks;
		}

		if ( Len( settings.onlyforips ?: "" ) ) {
			shouldLog = false;

			var clientIp = event.getClientIp();
			for( var ip in ListToArray( settings.onlyforips, Chr( 10 ) & Chr( 13 ) ) ) {
				if ( Trim( ip ) == clientIp ) {
					shouldLog = true;
					break;
				}
			}
		}

		if ( shouldLog && Len( settings.onlyforurls ?: "" ) ) {
			shouldLog = false;

			var currentUrl = event.getCurrentUrl( includeQueryString=false );
			for( var urlPattern in ListToArray( settings.onlyforurls, Chr( 10 ) & Chr( 13 ) ) ) {
				if ( ReFindNoCase( Trim( urlPattern ), currentUrl ) ) {
					shouldLog = true;
					break;
				}
			}
		}

		if ( shouldLog && Len( settings.excludeurls ?: "" ) ) {
			var currentUrl = event.getCurrentUrl( includeQueryString=false );
			for( var urlPattern in ListToArray( settings.excludeurls, Chr( 10 ) & Chr( 13 ) ) ) {
				if ( ReFindNoCase( Trim( urlPattern ), currentUrl ) ) {
					shouldLog = false;
					break;
				}
			}
		}

		return shouldLog;
	}

}