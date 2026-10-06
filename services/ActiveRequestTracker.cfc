/**
 * Records the ColdBox request running on each thread so a snapshot
 * taken from another thread can show how long it has been running
 * and which URL, event and page it belongs to.
 *
 * @presideService true
 * @singleton      true
 */
component {

	public any function init() {
		variables.startedAt  = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.urls       = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.events     = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.pageTypes  = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.pageTitles = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.kinds      = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.labels     = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();

		return this;
	}

	public void function begin( required any event ) {
		var threadId = _currentThreadId();

		variables.startedAt.put( threadId, JavaCast( "long", GetTickCount() ) );
		variables.urls.put( threadId, _urlOf( arguments.event ) );
		variables.events.put( threadId, _eventOf( arguments.event ) );
		variables.kinds.put( threadId, "http" );
		variables.pageTypes.remove( threadId );
		variables.pageTitles.remove( threadId );
		variables.labels.remove( threadId );
	}

	public void function beginTask( required string kind, required string label, required string eventName ) {
		var threadId     = _currentThreadId();
		var existingKind = variables.kinds.get( threadId );

		if ( !IsNull( local.existingKind ) && Len( local.existingKind ) ) {
			return;
		}

		if ( !_hasValue( variables.startedAt, threadId ) ) {
			variables.startedAt.put( threadId, JavaCast( "long", GetTickCount() ) );
		}

		variables.kinds.put( threadId, arguments.kind );
		variables.labels.put( threadId, arguments.label );
		variables.events.put( threadId, arguments.eventName );
		variables.urls.remove( threadId );
		variables.pageTypes.remove( threadId );
		variables.pageTitles.remove( threadId );
	}

	public boolean function hasRequest() {
		return _hasValue( variables.startedAt, _currentThreadId() );
	}

	public void function endTaskEvent( required string eventName ) {
		var threadId    = _currentThreadId();
		var requestKind = variables.kinds.get( threadId );

		if ( IsNull( local.requestKind ) || !ListFindNoCase( "task,adhoctask", local.requestKind ) ) {
			return;
		}

		var trackedEvent = variables.events.get( threadId );

		if ( IsNull( local.trackedEvent ) || CompareNoCase( local.trackedEvent, arguments.eventName ) ) {
			return;
		}

		end();
	}

	public void function noteEvent( required string eventName ) {
		var threadId = _currentThreadId();

		if ( !Len( arguments.eventName ) || _hasValue( variables.events, threadId ) ) {
			return;
		}
		if ( !_hasValue( variables.startedAt, threadId ) ) {
			variables.startedAt.put( threadId, JavaCast( "long", GetTickCount() ) );
		}

		variables.events.put( threadId, arguments.eventName );
	}

	public void function noteUrl( required string url ) {
		if ( !Len( arguments.url ) ) {
			return;
		}

		variables.urls.put( _currentThreadId(), arguments.url );
	}

	public void function notePage( required string pageType, required string pageTitle ) {
		var threadId = _currentThreadId();

		if ( Len( arguments.pageType ) ) {
			variables.pageTypes.put( threadId, arguments.pageType );
		}
		if ( Len( arguments.pageTitle ) ) {
			variables.pageTitles.put( threadId, arguments.pageTitle );
		}
	}

	public void function end() {
		var threadId = _currentThreadId();

		variables.startedAt.remove( threadId );
		variables.urls.remove( threadId );
		variables.events.remove( threadId );
		variables.pageTypes.remove( threadId );
		variables.pageTitles.remove( threadId );
		variables.kinds.remove( threadId );
		variables.labels.remove( threadId );
	}

	public struct function lookup( required string threadId ) {
		var requestStartTick = variables.startedAt.get( arguments.threadId );

		if ( IsNull( local.requestStartTick ) ) {
			return { found=false, elapsedMs=-1, url="", event="", pageType="", pageTitle="", kind="", label="" };
		}

		return {
			  found      = true
			, elapsedMs  = GetTickCount() - local.requestStartTick
			, url        = _stringValue( variables.urls, arguments.threadId )
			, event      = _stringValue( variables.events, arguments.threadId )
			, pageType   = _stringValue( variables.pageTypes, arguments.threadId )
			, pageTitle  = _stringValue( variables.pageTitles, arguments.threadId )
			, kind       = _stringValue( variables.kinds, arguments.threadId )
			, label      = _stringValue( variables.labels, arguments.threadId )
		};
	}

	private string function _currentThreadId() {
		return CreateObject( "java", "java.lang.Thread" ).currentThread().getId().toString();
	}

	private string function _urlOf( required any event ) {
		try {
			return arguments.event.getCurrentUrl();
		} catch ( any e ) {
			return "";
		}
	}

	private string function _eventOf( required any event ) {
		try {
			return arguments.event.getCurrentEvent();
		} catch ( any e ) {
			return "";
		}
	}

	private boolean function _hasValue( required any map, required string threadId ) {
		var value = arguments.map.get( arguments.threadId );

		return !IsNull( local.value ) && Len( local.value );
	}

	private string function _stringValue( required any map, required string threadId ) {
		var value = arguments.map.get( arguments.threadId );

		return IsNull( local.value ) ? "" : ToString( local.value );
	}

}
