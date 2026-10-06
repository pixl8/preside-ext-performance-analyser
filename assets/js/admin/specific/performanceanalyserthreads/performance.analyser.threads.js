( function( $ ){

	var $root        = $( ".perf-analyser-threads" );
	var snapshotUrl  = $root.data( "snapshotUrl" );
	var copyLabel    = $root.data( "copyLabel" ) || "Copy stack trace";
	var copiedLabel  = $root.data( "copiedLabel" ) || "Copied";
	var $tbody       = $( "#threads-tbody" );
	var $capturedAt  = $( "#threads-captured-at" );
	var $autoRefresh = $( "#threads-autorefresh" );
	var $refreshRate = $( "#threads-refresh-rate" );
	var snapshot     = { threads:[], summary:[] };
	var refreshTimer = null;

	if ( !$root.length || !snapshotUrl ) {
		return;
	}

	var escapeHtml = function( value ){
		return $( "<div/>" ).text( value == null ? "" : String( value ) ).html();
	};

	var formatElapsed = function( ms ){
		var seconds = Number( ms );
		if ( isNaN( seconds ) || seconds < 0 ) {
			return "";
		}
		seconds = seconds / 1000;
		if ( seconds < 1 ) {
			return seconds.toFixed( 3 ) + "s";
		}
		if ( seconds < 10 ) {
			return seconds.toFixed( 1 ) + "s";
		}
		return Math.round( seconds ) + "s";
	};

	var stackLines = function( thread ){
		if ( thread.cfmlStack && thread.cfmlStack.length ) {
			return thread.cfmlStack;
		}
		if ( thread.preside && thread.preside.highlights && thread.preside.highlights.length ) {
			return $.map( thread.preside.highlights, function( h ){
				return "[" + h.kind + "] " + ( h.label || h.frame );
			} );
		}
		return thread.stack || [];
	};

	var stackHtml = function( thread ){
		var lines = stackLines( thread );

		if ( !lines.length ) {
			return '<em class="light-grey">No stack frames</em>';
		}

		return '<pre style="max-height:18em;overflow:auto;white-space:pre-wrap;margin:0.5em 0 0;">' +
			escapeHtml( lines.join( "\n" ) ) +
		'</pre>';
	};

	var identityOf = function( thread ){
		return thread.identity || { icon:"fa-code", primary:"", secondary:"" };
	};

	var stackText = function( thread ){
		var identity = identityOf( thread );
		var lines    = [ '"' + thread.name + '" ' + thread.state ];

		if ( identity.primary ) {
			lines.push( identity.primary );
		}
		if ( identity.secondary ) {
			lines.push( identity.secondary );
		}

		return lines.concat( stackLines( thread ) ).join( "\n" );
	};

	var copyText = function( text ){
		var deferred = $.Deferred();

		if ( navigator.clipboard && window.isSecureContext ) {
			navigator.clipboard.writeText( text ).then( deferred.resolve, deferred.reject );
			return deferred.promise();
		}

		var $textarea = $( "<textarea/>" ).val( text ).css( { position:"fixed", top:0, left:0, opacity:0 } ).appendTo( "body" );

		$textarea[ 0 ].select();
		try {
			document.execCommand( "copy" ) ? deferred.resolve() : deferred.reject();
		} catch( e ) {
			deferred.reject();
		}
		$textarea.remove();

		return deferred.promise();
	};

	var renderThreads = function(){
		var html = [];

		$.each( snapshot.threads || [], function( i, thread ){
			var identity  = identityOf( thread );
			var secondary = identity.secondary
				? '<div class="light-grey"><small>' + escapeHtml( identity.secondary ) + '</small></div>'
				: "";

			html.push(
				'<tr class="thread-row" data-thread-index="' + i + '">' +
					'<td><div class="thread-identity">' +
						'<button type="button" class="btn btn-xs btn-link thread-toggle"><i class="fa fa-chevron-right"></i></button>' +
						'<i class="fa fa-fw ' + escapeHtml( identity.icon || "fa-code" ) + ' thread-identity-icon"></i>' +
						'<div class="thread-identity-text">' +
							'<div>' + escapeHtml( identity.primary ) + '</div>' +
							secondary +
						'</div>' +
					'</div></td>' +
					'<td><code>' + escapeHtml( thread.name ) + '</code></td>' +
					'<td>' + escapeHtml( thread.state ) + '</td>' +
					'<td class="text-right">' + escapeHtml( formatElapsed( thread.elapsedMs ) ) + '</td>' +
					'<td class="text-right"><button type="button" class="btn btn-xs btn-default thread-copy" title="' + escapeHtml( copyLabel ) + '"><i class="fa fa-copy"></i></button></td>' +
				'</tr>' +
				'<tr class="thread-stack-row hide" data-thread-index="' + i + '"><td colspan="5">' + stackHtml( thread ) + '</td></tr>'
			);
		} );

		if ( !html.length ) {
			html.push( '<tr><td colspan="5" class="text-center light-grey">No requests or CFML threads in progress.</td></tr>' );
		}

		$tbody.html( html.join( "" ) );
	};

	var loadSnapshot = function(){
		$.getJSON( snapshotUrl ).done( function( data ){
			snapshot = data || { threads:[], summary:[] };
			$capturedAt.text( snapshot.capturedAt ? ( "Captured " + snapshot.capturedAt ) : "" );
			renderThreads();
		} ).fail( function(){
			$tbody.html( '<tr><td colspan="5" class="text-center text-danger">Failed to load thread snapshot.</td></tr>' );
		} );
	};

	$root.on( "click", ".thread-toggle", function( e ){
		e.preventDefault();
		var $btn   = $( this );
		var $icon  = $btn.find( "i" );
		var index  = $btn.closest( "tr" ).data( "threadIndex" );
		var $stack = $tbody.find( ".thread-stack-row[data-thread-index='" + index + "']" );

		$stack.toggleClass( "hide" );
		$icon.toggleClass( "fa-chevron-right fa-chevron-down" );
	} );

	$root.on( "click", ".thread-copy", function( e ){
		e.preventDefault();
		var $btn   = $( this );
		var index  = $btn.closest( "tr" ).data( "threadIndex" );
		var thread = ( snapshot.threads || [] )[ index ];

		if ( !thread ) {
			return;
		}

		copyText( stackText( thread ) ).done( function(){
			$btn.attr( "title", copiedLabel ).find( "i" ).removeClass( "fa-copy" ).addClass( "fa-check" );
			setTimeout( function(){
				$btn.attr( "title", copyLabel ).find( "i" ).removeClass( "fa-check" ).addClass( "fa-copy" );
			}, 1500 );
		} );
	} );

	var refreshInterval = function(){
		var seconds = parseInt( $refreshRate.val(), 10 );

		if ( isNaN( seconds ) || seconds < 1 ) {
			seconds = 5;
		}

		return seconds * 1000;
	};

	var syncAutoRefresh = function(){
		if ( refreshTimer ) {
			clearInterval( refreshTimer );
			refreshTimer = null;
		}
		if ( $autoRefresh.is( ":checked" ) ) {
			refreshTimer = setInterval( loadSnapshot, refreshInterval() );
		}
	};

	$( "#threads-refresh-btn" ).on( "click", function( e ){
		e.preventDefault();
		loadSnapshot();
	} );

	$autoRefresh.on( "change", syncAutoRefresh );
	$refreshRate.on( "change", syncAutoRefresh );

	loadSnapshot();

} )( presideJQuery );
