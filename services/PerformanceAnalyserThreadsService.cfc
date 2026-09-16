/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public struct function getThreadSnapshot() {
		var threadMxBean = CreateObject( "java", "java.lang.management.ManagementFactory" ).getThreadMXBean();

		if ( !threadMxBean.isThreadCpuTimeEnabled() ) {
			try {
				threadMxBean.setThreadCpuTimeEnabled( true );
			} catch ( any e ) {
				// some JVMs disallow enabling CPU time
			}
		}

		var allStacks = CreateObject( "java", "java.lang.Thread" ).getAllStackTraces();
		var iterator  = allStacks.entrySet().iterator();
		var threads   = [];
		var byState   = {};

		while ( iterator.hasNext() ) {
			var entry      = iterator.next();
			var javaThread = entry.getKey();
			var stackArr   = entry.getValue();
			var threadId   = javaThread.getId();
			var state      = javaThread.getState().toString();
			var cpuNs      = threadMxBean.getThreadCpuTime( threadId );
			var cpuMs      = ( cpuNs > 0 ) ? ( cpuNs / 1000000 ) : 0;
			var stack      = _stackToArray( stackArr );
			var truncated  = _truncateAtServlet( stack );
			var cfmlStack  = _extractCfmlStack( truncated );
			var preside    = _decoratePreside( truncated, cfmlStack, javaThread.getName() );

			if ( !StructKeyExists( byState, state ) ) {
				byState[ state ] = { state=state, count=0, cpuTotalMs=0 };
			}
			byState[ state ].count++;
			byState[ state ].cpuTotalMs += cpuMs;

			ArrayAppend( threads, {
				  id         = threadId
				, name       = javaThread.getName()
				, state      = state
				, daemon     = javaThread.isDaemon()
				, group      = _safeThreadGroupName( javaThread )
				, cpuTimeMs  = cpuMs
				, stack      = truncated
				, cfmlStack  = cfmlStack
				, preside    = preside
			} );
		}

		ArraySort( threads, function( a, b ) {
			if ( a.cpuTimeMs == b.cpuTimeMs ) {
				return CompareNoCase( a.name, b.name );
			}
			return ( a.cpuTimeMs > b.cpuTimeMs ) ? -1 : 1;
		} );

		var summary = [];
		for( var stateKey in byState ) {
			ArrayAppend( summary, byState[ stateKey ] );
		}
		ArraySort( summary, function( a, b ) {
			return ( a.cpuTotalMs > b.cpuTotalMs ) ? -1 : 1;
		} );

		ArrayPrepend( summary, {
			  state      = "ALL"
			, count      = ArrayLen( threads )
			, cpuTotalMs = _sumCpu( threads )
		} );

		return {
			  capturedAt = DateTimeFormat( Now(), "yyyy-mm-dd HH:nn:ss" )
			, summary    = summary
			, threads    = threads
		};
	}

// PRIVATE HELPERS
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

		if ( ArrayLen( arguments.cfmlStack ) || FindNoCase( "lucee.", stackText ) || FindNoCase( "coldbox.", stackText ) ) {
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
			, isCfml     = ArrayLen( arguments.cfmlStack ) > 0 || kind != "jvm"
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

	private string function _safeThreadGroupName( required any javaThread ) {
		try {
			var group = arguments.javaThread.getThreadGroup();
			if ( !IsNull( group ) ) {
				return group.getName();
			}
		} catch ( any e ) {}
		return "";
	}

	private numeric function _sumCpu( required array threads ) {
		var total = 0;
		for( var t in arguments.threads ) {
			total += Val( t.cpuTimeMs ?: 0 );
		}
		return total;
	}

}
