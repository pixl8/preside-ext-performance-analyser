/**
 * @presideService true
 * @singleton      true
 */
component {

	property name="threaddumpDao"           inject="presidecms:object:perf_analyser_threaddump";
	property name="activeRequestTracker"    inject="activeRequestTracker";
	property name="taskManagerService"      inject="delayedInjector:taskManagerService";
	property name="adHocTaskManagerService" inject="delayedInjector:adHocTaskManagerService";

// CONSTRUCTOR
	public any function init() {
		variables.adhocWrapped = false;

		return this;
	}

// PUBLIC API METHODS
	public struct function getThreadSnapshot() {
		_ensureAdhocWrapped();

		var activeThreads = _getActiveCfmlThreads();
		var threads       = [];
		var byKind        = {};

		for( var activeThread in activeThreads ) {
			var kind = activeThread.preside.kind;

			if ( !StructKeyExists( byKind, kind ) ) {
				byKind[ kind ] = { label=kind, count=0 };
			}
			byKind[ kind ].count++;

			var threadForBrowser = StructCopy( activeThread );
			StructDelete( threadForBrowser, "fullStack" );
			ArrayAppend( threads, threadForBrowser );
		}

		var summary = [];
		for( var kindKey in byKind ) {
			ArrayAppend( summary, byKind[ kindKey ] );
		}
		ArraySort( summary, function( a, b ) {
			return ( a.count > b.count ) ? -1 : 1;
		} );

		ArrayPrepend( summary, {
			  label = "ALL"
			, count = ArrayLen( threads )
		} );

		return {
			  capturedAt = DateTimeFormat( Now(), "yyyy-mm-dd HH:nn:ss" )
			, summary    = summary
			, threads    = threads
		};
	}

	public string function saveThreadDump() {
		_ensureAdhocWrapped();

		var threads     = _collectThreads( activeOnly=false );
		var label       = DateTimeFormat( Now(), "yyyy-mm-dd HH:nn:ss" );
		var stored      = [];
		var activeCount = 0;

		for ( var thread in threads ) {
			var identity = thread.identity ?: {};

			if ( thread.activeCfml ) {
				activeCount++;
			}

			ArrayAppend( stored, {
				  name       = thread.name
				, id         = ToString( thread.id )
				, state      = thread.state
				, elapsed    = _formatElapsed( thread.elapsedMs )
				, activeCfml = thread.activeCfml
				, primary    = identity.primary ?: ""
				, secondary  = identity.secondary ?: ""
				, cfmlStack  = thread.cfmlStack
				, javaStack  = thread.fullStack
			} );
		}

		return threaddumpDao.insertData( {
			  label        = label
			, thread_count = activeCount
			, dump_text    = SerializeJSON( {
				  capturedAt  = label
				, activeCount = activeCount
				, threads     = stored
			} )
		} );
	}

	public struct function getThreadDump( required string dumpId ) {
		var record = threaddumpDao.selectData(
			  id           = arguments.dumpId
			, selectFields = [ "id", "label", "thread_count", "dump_text", "datecreated" ]
		);

		for( var row in record ) {
			return row;
		}

		return {};
	}

// PRIVATE HELPERS
	private array function _getActiveCfmlThreads() {
		return _collectThreads( activeOnly=true );
	}

	private array function _collectThreads( boolean activeOnly=true ) {
		var javaThreads = CreateObject( "java", "java.lang.Thread" );
		var ownThreadId = javaThreads.currentThread().getId();
		var iterator    = javaThreads.getAllStackTraces().entrySet().iterator();
		var threads     = [];

		while ( iterator.hasNext() ) {
			var entry      = iterator.next();
			var javaThread = entry.getKey();
			var threadId   = javaThread.getId();
			var state      = javaThread.getState().toString();

			if ( threadId == ownThreadId ) {
				continue;
			}

			var requestInfo = activeRequestTracker.lookup( threadId.toString() );

			if ( arguments.activeOnly && !requestInfo.found && state != "RUNNABLE" ) {
				continue;
			}

			var stack     = _stackToArray( entry.getValue() );
			var truncated = _truncateAtServlet( stack );
			var cfmlStack = _extractCfmlStack( truncated );
			var preside   = _decoratePreside( truncated, cfmlStack, javaThread.getName() );

			var activeCfml = requestInfo.found || ( state == "RUNNABLE" && preside.isCfml );

			if ( arguments.activeOnly && !activeCfml ) {
				continue;
			}

			if ( requestInfo.found && requestInfo.kind == "task" && !Len( requestInfo.label ?: "" ) ) {
				requestInfo.label = _scheduledTaskName( requestInfo.event ?: "" );
			}

			preside.summary = _requestSummary( requestInfo, preside.summary );

			ArrayAppend( threads, {
				  id          = threadId
				, name        = javaThread.getName()
				, state       = state
				, daemon      = javaThread.isDaemon()
				, group       = _safeThreadGroupName( javaThread )
				, elapsedMs   = requestInfo.found ? requestInfo.elapsedMs : -1
				, activeCfml  = activeCfml
				, requestInfo = requestInfo
				, identity    = _requestIdentity( requestInfo, preside )
				, stack       = truncated
				, fullStack   = stack
				, cfmlStack   = cfmlStack
				, preside     = preside
			} );
		}

		ArraySort( threads, function( a, b ) {
			if ( ( a.activeCfml ?: false ) != ( b.activeCfml ?: false ) ) {
				return ( a.activeCfml ?: false ) ? -1 : 1;
			}
			if ( a.elapsedMs == b.elapsedMs ) {
				return CompareNoCase( a.name, b.name );
			}
			return ( a.elapsedMs > b.elapsedMs ) ? -1 : 1;
		} );

		return threads;
	}

	private array function _stackToArray( required any stackArr ) {
		var frames = [];
		if ( IsNull( arguments.stackArr ) ) {
			return frames;
		}

		for( var ste in arguments.stackArr ) {
			ArrayAppend( frames, ste.toString() );
		}

		return frames;
	}

	private array function _truncateAtServlet( required array stack ) {
		var out = [];
		for( var frame in arguments.stack ) {
			if ( FindNoCase( "lucee.loader.servlet.CFMLServlet.service", frame )
			  || FindNoCase( "lucee.runtime.listener", frame ) && FindNoCase( "execute", frame )
			) {
				ArrayAppend( out, "..." );
				break;
			}
			ArrayAppend( out, frame );
		}
		return out;
	}

	private array function _extractCfmlStack( required array stack ) {
		var cfml = [];
		var seen = {};

		for( var frame in arguments.stack ) {
			var matches = ReMatchNoCase( "\(([^)]+\.(cfc|cfm|lucee):[0-9]+)\)", frame );
			for( var m in matches ) {
				var cleaned = ListFirst( m, "()" );
				if ( !StructKeyExists( seen, cleaned ) ) {
					seen[ cleaned ] = true;
					ArrayAppend( cfml, cleaned );
				}
			}

			var pathMatches = ReMatchNoCase( "\[([^\]]+\.(cfc|cfm|lucee)[^\]]*)\]", frame );
			for( var pm in pathMatches ) {
				var cleanedPath = ListFirst( pm, "[]" );
				if ( !StructKeyExists( seen, cleanedPath ) ) {
					seen[ cleanedPath ] = true;
					ArrayAppend( cfml, cleanedPath );
				}
			}
		}

		return cfml;
	}

	private struct function _decoratePreside( required array stack, required array cfmlStack, required string threadName ) {
		var tags        = [];
		var highlights  = [];
		var kind        = "jvm";
		var summary     = "";
		var stackText   = ArrayToList( arguments.stack, " " );
		var name        = arguments.threadName;
		var runsCfml    = ArrayLen( arguments.cfmlStack ) || FindNoCase( "lucee.", stackText ) || FindNoCase( "coldbox.", stackText );

		if ( runsCfml ) {
			kind = "cfml";
		}

		if ( FindNoCase( "AdHocTask", stackText ) || FindNoCase( "adhoc", name ) || FindNoCase( "_runningAdhocTaskId", stackText ) ) {
			kind = "adhoctask";
			ArrayAppend( tags, "adhoc-task" );
		} else if ( FindNoCase( "TaskManager", stackText ) || FindNoCase( "taskmanager", name ) || FindNoCase( "ScheduledTask", stackText ) ) {
			kind = "task";
			ArrayAppend( tags, "scheduled-task" );
		} else if ( FindNoCase( "CFMLServlet", stackText ) || FindNoCase( "http-", LCase( name ) ) || FindNoCase( "ajp-", LCase( name ) ) || FindNoCase( "default task-", LCase( name ) ) ) {
			if ( kind != "adhoctask" && kind != "task" ) {
				kind = "http";
				ArrayAppend( tags, "request" );
			}
		}

		if ( FindNoCase( "BackgroundThread", stackText ) || FindNoCase( "isBackgroundThread", stackText ) ) {
			ArrayAppend( tags, "background" );
		}

		var i = 0;
		for( var frame in arguments.stack ) {
			i++;
			var highlight = _classifyFrame( frame );
			if ( Len( highlight.kind ) ) {
				ArrayAppend( highlights, {
					  index = i
					, kind  = highlight.kind
					, label = highlight.label
					, frame = frame
				} );
				if ( !ArrayFindNoCase( tags, highlight.kind ) ) {
					ArrayAppend( tags, highlight.kind );
				}
				if ( !Len( summary ) && ListFindNoCase( "handler,interceptor,service,view", highlight.kind ) ) {
					summary = highlight.label;
				}
			}
		}

		if ( !Len( summary ) && ArrayLen( arguments.cfmlStack ) ) {
			summary = arguments.cfmlStack[ 1 ];
		}

		return {
			  kind       = kind
			, tags       = tags
			, highlights = highlights
			, summary    = summary
			, isCfml     = runsCfml
		};
	}

	private struct function _classifyFrame( required string frame ) {
		var f = arguments.frame;

		if ( ReFindNoCase( "[/\\]handlers[/\\]", f ) || FindNoCase( ".handlers.", f ) ) {
			return { kind="handler", label=_shortenFrame( f ) };
		}
		if ( ReFindNoCase( "[/\\]interceptors[/\\]", f ) || FindNoCase( ".interceptors.", f ) ) {
			return { kind="interceptor", label=_shortenFrame( f ) };
		}
		if ( ReFindNoCase( "[/\\]services[/\\]", f ) || FindNoCase( ".services.", f ) ) {
			return { kind="service", label=_shortenFrame( f ) };
		}
		if ( ReFindNoCase( "[/\\]views[/\\]", f ) || FindNoCase( ".views.", f ) ) {
			return { kind="view", label=_shortenFrame( f ) };
		}
		if ( FindNoCase( "coldbox.system", f ) ) {
			return { kind="coldbox", label=_shortenFrame( f ) };
		}
		if ( ReFindNoCase( "\.(cfc|cfm|lucee)", f ) ) {
			return { kind="cfml", label=_shortenFrame( f ) };
		}

		return { kind="", label="" };
	}

	private string function _shortenFrame( required string frame ) {
		var src = arguments.frame;
		src = ReReplaceNoCase( src, "^.*?[/\\]website[/\\]", "" );
		src = ReReplaceNoCase( src, "^.*?[/\\]application[/\\]", "application/" );
		src = ReReplaceNoCase( src, "^.*?[/\\]preside[/\\]system[/\\]", "preside/system/" );
		return src;
	}

	private struct function _requestIdentity( required struct requestInfo, required struct preside ) {
		var info = arguments.requestInfo;
		var kind = info.kind ?: "";

		if ( !Len( kind ) ) {
			kind = arguments.preside.kind ?: "";
		}

		if ( Len( info.pageType ?: "" ) ) {
			return {
				  icon      = "fa-sitemap"
				, primary   = info.url ?: ""
				, secondary = _pageTypeName( info.pageType )
			};
		}

		if ( kind == "task" ) {
			return {
				  icon      = "fa-clock-o"
				, primary   = _taskHeading( "performanceanalyser:threads.identity.scheduled", _taskLabel( info, arguments.preside ) )
				, secondary = ""
			};
		}

		if ( kind == "adhoctask" ) {
			return {
				  icon      = "fa-play-circle"
				, primary   = _taskHeading( "performanceanalyser:threads.identity.adhoc", _taskLabel( info, arguments.preside ) )
				, secondary = ""
			};
		}

		if ( info.found ) {
			return {
				  icon      = "fa-bolt"
				, primary   = info.url ?: ""
				, secondary = info.event ?: ""
			};
		}

		return {
			  icon      = "fa-code"
			, primary   = arguments.preside.summary ?: ""
			, secondary = ""
		};
	}

	private string function _taskLabel( required struct requestInfo, required struct preside ) {
		if ( Len( arguments.requestInfo.label ?: "" ) ) {
			return arguments.requestInfo.label;
		}
		if ( Len( arguments.requestInfo.event ?: "" ) ) {
			return arguments.requestInfo.event;
		}

		return arguments.preside.summary ?: "";
	}

	private string function _taskHeading( required string uri, required string name ) {
		var prefix = $translateResource( uri=arguments.uri );

		if ( !Len( arguments.name ) ) {
			return prefix;
		}

		return prefix & ": " & arguments.name;
	}

	private string function _pageTypeName( required string pageType ) {
		var uri        = "page-types.#arguments.pageType#:name";
		var translated = $translateResource( uri=uri, defaultValue=arguments.pageType );

		if ( translated == uri ) {
			return arguments.pageType;
		}

		return translated;
	}

	private string function _scheduledTaskName( required string eventName ) {
		if ( !Len( arguments.eventName ) ) {
			return "";
		}

		var names = _taskNamesByEvent();

		return names[ arguments.eventName ] ?: arguments.eventName;
	}

	private struct function _taskNamesByEvent() {
		if ( StructKeyExists( variables, "taskNamesByEvent" ) ) {
			return variables.taskNamesByEvent;
		}

		var names = {};

		try {
			var taskManager = taskManagerService.get();

			for ( var taskKey in taskManager.listTasks() ) {
				var task = taskManager.getTask( taskKey );

				if ( Len( task.event ?: "" ) ) {
					names[ task.event ] = task.name ?: taskKey;
				}
			}
		} catch ( any e ) {
			return names;
		}

		variables.taskNamesByEvent = names;

		return names;
	}

	private void function _ensureAdhocWrapped() {
		if ( variables.adhocWrapped ) {
			return;
		}

		var taskService = "";

		try {
			taskService = adHocTaskManagerService.get();
		} catch ( any e ) {
			return;
		}

		lock name="perfAnalyserAdhocWrap" type="exclusive" timeout="5" {
			if ( variables.adhocWrapped || StructKeyExists( taskService, "_perfAnalyserRunTaskWrapped" ) ) {
				variables.adhocWrapped = true;
				return;
			}

			var tracker = activeRequestTracker;

			taskService.originalRunTask = taskService.runTask;
			StructDelete( taskService, "runTask" );

			taskService.runTask = function() {
				if ( tracker.hasRequest() ) {
					return taskService.originalRunTask( argumentCollection=arguments );
				}

				var taskId    = arguments.taskId ?: ( arguments[ 1 ] ?: "" );
				var label     = "";
				var eventName = "";

				try {
					var task = taskService.getTask( taskId );

					if ( task.recordCount ) {
						label     = task.title ?: "";
						eventName = task.event ?: "";
					}
				} catch ( any e ) {}

				if ( !Len( label ) ) {
					label = eventName;
				}

				tracker.beginTask( kind="adhoctask", label=label, eventName=eventName );

				try {
					return taskService.originalRunTask( argumentCollection=arguments );
				} finally {
					tracker.end();
				}
			};

			taskService._perfAnalyserRunTaskWrapped = true;
			variables.adhocWrapped                  = true;
		}
	}

	private string function _requestSummary( required struct requestInfo, required string fallback ) {
		var parts = [];

		if ( Len( arguments.requestInfo.url ?: "" ) ) {
			ArrayAppend( parts, arguments.requestInfo.url );
		}
		if ( Len( arguments.requestInfo.pageType ?: "" ) ) {
			ArrayAppend( parts, arguments.requestInfo.pageType );
		}
		if ( Len( arguments.requestInfo.pageTitle ?: "" ) ) {
			ArrayAppend( parts, arguments.requestInfo.pageTitle );
		}
		if ( Len( arguments.requestInfo.event ?: "" ) ) {
			ArrayAppend( parts, arguments.requestInfo.event );
		}
		if ( ArrayLen( parts ) ) {
			return ArrayToList( parts, " · " );
		}

		return arguments.fallback;
	}

	private string function _formatElapsed( required numeric elapsedMs ) {
		if ( arguments.elapsedMs < 0 ) {
			return "unknown";
		}

		return NumberFormat( arguments.elapsedMs / 1000, "0.000" ) & "s";
	}

	private string function _safeThreadGroupName( required any javaThread ) {
		try {
			var group = arguments.javaThread.getThreadGroup();
			if ( !IsNull( group ) ) {
				return group.getName();
			}
		} catch ( any e ) {}
		return "";
	}

}
