/**
 * @presideService true
 * @singleton      true
 */
component {

	public any function init() {
		variables.allocationSupported = false;

		return this;
	}

	public boolean function isActive() {
		if ( StructKeyExists( request, "_perfAnalyserAllocActive" ) ) {
			return request._perfAnalyserAllocActive;
		}

		var active = _isConfiguredOn();
		if ( active ) {
			active = _ensureThreadMxBean();
		}

		request._perfAnalyserAllocActive = active;

		return active;
	}

	public string function start( required string kind, required string name ) {
		if ( !isActive() || !Len( arguments.name ) ) {
			return "";
		}

		var state = _state();
		var frame = {
			  id         = "f#++state.nextId#"
			, kind       = Left( arguments.kind, 20 )
			, name       = Left( arguments.name, 255 )
			, startBytes = 0
			, childBytes = 0
		};

		ArrayAppend( state.stack, frame );
		frame.startBytes = _allocatedBytes();

		return frame.id;
	}

	public void function stop( required string frameId ) {
		if ( !Len( arguments.frameId ) || !StructKeyExists( request, "_perfAnalyserAlloc" ) ) {
			return;
		}

		var state = request._perfAnalyserAlloc;
		var index = _indexOfFrame( state.stack, arguments.frameId );

		if ( !index ) {
			return;
		}

		while ( ArrayLen( state.stack ) >= index ) {
			_closeTop( state );
		}
	}

	public void function closeOpenFrames() {
		if ( !StructKeyExists( request, "_perfAnalyserAlloc" ) ) {
			return;
		}

		var state = request._perfAnalyserAlloc;

		while ( ArrayLen( state.stack ) ) {
			_closeTop( state );
		}
	}

	public array function getRows() {
		if ( !StructKeyExists( request, "_perfAnalyserAlloc" ) ) {
			return [];
		}

		var rows = [];

		for( var key in request._perfAnalyserAlloc.totals ) {
			ArrayAppend( rows, request._perfAnalyserAlloc.totals[ key ] );
		}

		return rows;
	}

	private boolean function _isConfiguredOn() {
		try {
			var enabled  = $helpers.isTrue( $getPresideSetting( "performanceAnalyserDebug", "enabled" ) );
			var tracking = $helpers.isTrue( $getPresideSetting( "performanceAnalyserDebug", "trackallocation" ) );

			return enabled && tracking;
		} catch ( any e ) {
			return false;
		}
	}

	private boolean function _ensureThreadMxBean() {
		if ( variables.allocationSupported ) {
			return true;
		}

		try {
			var bean       = CreateObject( "java", "java.lang.management.ManagementFactory" ).getThreadMXBean();
			var iface      = CreateObject( "java", "java.lang.Class" ).forName( "com.sun.management.ThreadMXBean" );
			var classClass = CreateObject( "java", "java.lang.Class" ).forName( "java.lang.Class" );
			var emptyArgs  = CreateObject( "java", "java.lang.reflect.Array" ).newInstance( classClass, 0 );
			var supported  = iface.getMethod( "isThreadAllocatedMemorySupported", emptyArgs ).invoke( bean, emptyArgs );

			if ( supported ) {
				var enabled = iface.getMethod( "isThreadAllocatedMemoryEnabled", emptyArgs ).invoke( bean, emptyArgs );

				if ( !enabled ) {
					var boolTypes = CreateObject( "java", "java.lang.reflect.Array" ).newInstance( classClass, 1 );
					var setArgs   = CreateObject( "java", "java.lang.reflect.Array" ).newInstance( CreateObject( "java", "java.lang.Object" ).getClass(), 1 );

					boolTypes[ 1 ] = CreateObject( "java", "java.lang.Boolean" ).TYPE;
					setArgs[ 1 ]   = true;
					iface.getMethod( "setThreadAllocatedMemoryEnabled", boolTypes ).invoke( bean, setArgs );
				}

				variables.threadMxBean         = bean;
				variables.allocatedBytesMethod = iface.getMethod( "getCurrentThreadAllocatedBytes", emptyArgs );
				variables.emptyArgs            = emptyArgs;
				variables.allocationSupported  = true;

				return true;
			}
		} catch ( any e ) {
			variables.allocationSupported = false;
		}

		return false;
	}

	private struct function _state() {
		if ( !StructKeyExists( request, "_perfAnalyserAlloc" ) ) {
			request._perfAnalyserAlloc = {
				  stack  = []
				, totals = {}
				, nextId = 0
			};
		}

		return request._perfAnalyserAlloc;
	}

	private numeric function _allocatedBytes() {
		var bytes = variables.allocatedBytesMethod.invoke( variables.threadMxBean, variables.emptyArgs );

		if ( bytes < 0 ) {
			return 0;
		}

		return bytes;
	}

	private numeric function _indexOfFrame( required array stack, required string frameId ) {
		var i = 0;

		for( i = ArrayLen( arguments.stack ); i >= 1; i-- ) {
			if ( arguments.stack[ i ].id == arguments.frameId ) {
				return i;
			}
		}

		return 0;
	}

	private void function _closeTop( required struct state ) {
		var stack = arguments.state.stack;
		var depth = ArrayLen( stack );

		if ( !depth ) {
			return;
		}

		var frame      = stack[ depth ];
		var inclusive  = _allocatedBytes() - frame.startBytes;
		var pathHash   = _stackHash( stack, depth );
		var parentHash = depth > 1 ? _stackHash( stack, depth - 1 ) : "-";
		var exclusive  = 0;

		ArrayDeleteAt( stack, depth );

		if ( inclusive < 0 ) {
			inclusive = 0;
		}

		exclusive = inclusive - frame.childBytes;
		if ( exclusive < 0 ) {
			exclusive = 0;
		}

		if ( ArrayLen( stack ) ) {
			stack[ ArrayLen( stack ) ].childBytes += inclusive;
		}

		_record(
			  state      = arguments.state
			, kind       = frame.kind
			, name       = frame.name
			, inclusive  = inclusive
			, exclusive  = exclusive
			, pathHash   = pathHash
			, parentHash = parentHash
		);
	}

	private string function _stackHash( required array stack, required numeric depth ) {
		var parts = [];
		var i     = 0;

		for ( i = 1; i <= arguments.depth; i++ ) {
			ArrayAppend( parts, arguments.stack[ i ].kind & Chr( 1 ) & arguments.stack[ i ].name );
		}

		return LCase( Hash( ArrayToList( parts, Chr( 2 ) ) ) );
	}

	private void function _record(
		  required struct  state
		, required string  kind
		, required string  name
		, required numeric inclusive
		, required numeric exclusive
		, required string  pathHash
		, required string  parentHash
	) {
		var key    = Len( arguments.pathHash ) ? arguments.pathHash : ( arguments.kind & Chr( 1 ) & arguments.name );
		var bucket = arguments.state.totals[ key ] ?: "";

		if ( !IsStruct( bucket ) ) {
			bucket = {
				  kind             = arguments.kind
				, name             = arguments.name
				, call_count       = 0
				, inclusive_bytes  = 0
				, exclusive_bytes  = 0
				, max_inclusive    = 0
				, max_exclusive    = 0
				, path_hash        = arguments.pathHash
				, parent_hash      = arguments.parentHash
			};
			arguments.state.totals[ key ] = bucket;
		}

		bucket.call_count++;
		bucket.inclusive_bytes += arguments.inclusive;
		bucket.exclusive_bytes += arguments.exclusive;

		if ( arguments.inclusive > bucket.max_inclusive ) {
			bucket.max_inclusive = arguments.inclusive;
		}
		if ( arguments.exclusive > bucket.max_exclusive ) {
			bucket.max_exclusive = arguments.exclusive;
		}
	}

}
