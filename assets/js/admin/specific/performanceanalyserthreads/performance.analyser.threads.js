( function( $ ){

	var $root          = $( ".perf-analyser-threads" );
	var snapshotUrl    = $root.data( "snapshotUrl" );
	var $tbody         = $( "#threads-tbody" );
	var $summary       = $( "#threads-summary" );
	var $capturedAt    = $( "#threads-captured-at" );
	var $stateFilter   = $( "#threads-filter-state" );
	var $nameFilter    = $( "#threads-filter-name" );
	var $cfmlOnly      = $( "#threads-filter-cfml" );
	var $autoRefresh   = $( "#threads-autorefresh" );
	var snapshot       = { threads:[], summary:[] };
	var refreshTimer   = null;
	var viewMode       = "preside";

	if ( !$root.length || !snapshotUrl ) {
		return;
	}

	var escapeHtml = function( value ){
		return $( "<div/>" ).text( value == null ? "" : String( value ) ).html();
	};

	var formatCpu = function( ms ){
		var seconds = ( Number( ms ) || 0 ) / 1000;
		if ( seconds < 1 ) {
			return seconds.toFixed( 3 ) + "s";
		}
		return seconds.toFixed( 1 ) + "s";
	};

	var getViewMode = function(){
		return $( "input[name=threads-view-mode]:checked" ).val() || "preside";
	};

	var renderSummary = function(){
		var html = [];
		$.each( snapshot.summary || [], function( i, row ){
			html.push(
				'<span class="label label-info" style="margin-right:0.5em;">' +
					escapeHtml( row.state ) +
					' (' + escapeHtml( row.count ) + ') ' +
					escapeHtml( formatCpu( row.cpuTotalMs ) ) +
				'</span>'
			);
		} );
		$summary.html( html.join( " " ) || "&nbsp;" );
	};

	var populateStateFilter = function(){
		var current = $stateFilter.val();
		var states  = {};
		$.each( snapshot.threads || [], function( i, t ){
			states[ t.state ] = true;
		} );
		$stateFilter.find( "option:not(:first)" ).remove();
		Object.keys( states ).sort().forEach( function( state ){
			$stateFilter.append( $( "<option/>" ).val( state ).text( state ) );
		} );
		if ( current ) {
			$stateFilter.val( current );
		}
	};

	var stackHtml = function( thread ){
		var mode = getViewMode();
		var lines;

		if ( mode === "preside" ) {
			if ( thread.cfmlStack && thread.cfmlStack.length ) {
				lines = thread.cfmlStack;
			} else if ( thread.preside && thread.preside.highlights && thread.preside.highlights.length ) {
				lines = $.map( thread.preside.highlights, function( h ){
					return "[" + h.kind + "] " + ( h.label || h.frame );
				} );
			} else {
				lines = thread.stack || [];
			}
		} else {
			lines = thread.stack || [];
		}

		if ( !lines.length ) {
			return '<em class="light-grey">No stack frames</em>';
		}

		return '<pre style="max-height:18em;overflow:auto;white-space:pre-wrap;margin:0.5em 0 0;">' +
			escapeHtml( lines.join( "\n" ) ) +
		'</pre>';
	};

	var matchesFilters = function( thread ){
		var nameQ  = $.trim( $nameFilter.val() || "" ).toLowerCase();
		var stateQ = $stateFilter.val();
		var cfml   = $cfmlOnly.is( ":checked" );

		if ( nameQ && String( thread.name || "" ).toLowerCase().indexOf( nameQ ) === -1 ) {
			return false;
		}
		if ( stateQ && thread.state !== stateQ ) {
			return false;
		}
		if ( cfml && !( thread.preside && thread.preside.isCfml ) ) {
			return false;
		}
		return true;
	};

	var renderThreads = function(){
		var html = [];
		var mode = getViewMode();

		$.each( snapshot.threads || [], function( i, thread ){
			if ( !matchesFilters( thread ) ) {
				return;
			}

			var kind    = ( thread.preside && thread.preside.kind ) ? thread.preside.kind : "jvm";
			var summary = mode === "preside"
				? ( ( thread.preside && thread.preside.summary ) || ( thread.cfmlStack && thread.cfmlStack[0] ) || "" )
				: ( ( thread.stack && thread.stack[0] ) || "" );
			var tags = ( thread.preside && thread.preside.tags ) ? thread.preside.tags : [];
			var tagHtml = $.map( tags, function( tag ){
				return '<span class="label" style="margin-right:0.25em;">' + escapeHtml( tag ) + '</span>';
			} ).join( "" );

			html.push(
				'<tr class="thread-row" data-thread-index="' + i + '">' +
					'<td><button type="button" class="btn btn-xs btn-link thread-toggle"><i class="fa fa-chevron-right"></i></button></td>' +
					'<td><code>' + escapeHtml( thread.name ) + '</code></td>' +
					'<td>' + escapeHtml( thread.state ) + '</td>' +
					'<td>' + escapeHtml( kind ) + ( tagHtml ? '<div>' + tagHtml + '</div>' : '' ) + '</td>' +
					'<td><small>' + escapeHtml( summary ) + '</small></td>' +
					'<td class="text-right">' + escapeHtml( formatCpu( thread.cpuTimeMs ) ) + '</td>' +
				'</tr>' +
				'<tr class="thread-stack-row hide" data-thread-index="' + i + '"><td colspan="6">' + stackHtml( thread ) + '</td></tr>'
			);
		} );

		if ( !html.length ) {
			html.push( '<tr><td colspan="6" class="text-center light-grey">No threads match the current filters.</td></tr>' );
		}

		$tbody.html( html.join( "" ) );
	};

	var loadSnapshot = function(){
		$tbody.html( '<tr><td colspan="6" class="text-center light-grey">Loading…</td></tr>' );

		$.getJSON( snapshotUrl ).done( function( data ){
			snapshot = data || { threads:[], summary:[] };
			$capturedAt.text( snapshot.capturedAt ? ( "Captured " + snapshot.capturedAt ) : "" );
			renderSummary();
			populateStateFilter();
			renderThreads();
		} ).fail( function(){
			$tbody.html( '<tr><td colspan="6" class="text-center text-danger">Failed to load thread snapshot.</td></tr>' );
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

	$( "input[name=threads-view-mode]" ).on( "change", function(){
		viewMode = getViewMode();
		renderThreads();
	} );

	$nameFilter.on( "keyup change", renderThreads );
	$stateFilter.on( "change", renderThreads );
	$cfmlOnly.on( "change", renderThreads );

	$( "#threads-refresh-btn" ).on( "click", function( e ){
		e.preventDefault();
		loadSnapshot();
	} );

	$autoRefresh.on( "change", function(){
		if ( refreshTimer ) {
			clearInterval( refreshTimer );
			refreshTimer = null;
		}
		if ( $autoRefresh.is( ":checked" ) ) {
			refreshTimer = setInterval( loadSnapshot, 5000 );
		}
	} );

	loadSnapshot();

} )( presideJQuery );
