( function( $ ){

	var $root = $( ".perf-analyser-threaddump" );
	var $text = $( "#threaddump-text" );

	if ( !$root.length || !$text.length ) {
		return;
	}

	var copiedLabel = $root.data( "copiedLabel" ) || "Copied";

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

	var flashCopied = function( $btn ){
		var $label    = $btn.find( ".threaddump-copy-label" );
		var $icon     = $btn.find( "i" );
		var copyLabel = $label.data( "copyLabel" );

		if ( !copyLabel ) {
			copyLabel = $label.text();
			$label.data( "copyLabel", copyLabel );
		}

		$label.text( copiedLabel );
		$icon.removeClass( "fa-copy" ).addClass( "fa-check" );
		setTimeout( function(){
			$label.text( copyLabel );
			$icon.removeClass( "fa-check" ).addClass( "fa-copy" );
		}, 1500 );
	};

	var $data = $( "#threaddump-data" );

	if ( !$data.length ) {
		$( "#threaddump-copy-btn" ).on( "click", function( e ){
			e.preventDefault();
			var $btn = $( this );

			copyText( $text.text() ).done( function(){
				flashCopied( $btn );
			} );
		} );
		return;
	}

	var dump         = JSON.parse( $data.text() );
	var threads      = dump.threads || [];
	var $activeOnly  = $( "#threaddump-active-only" );
	var $count       = $( "#threaddump-count" );
	var stackMode    = "cfml";
	var scopeActive  = $root.data( "scopeActive" ) || "Active CFML requests";
	var scopeAll     = $root.data( "scopeAll" ) || "All threads";
	var modeCfml     = $root.data( "modeCfml" ) || "CFML stack";
	var modeJava     = $root.data( "modeJava" ) || "Full Java";
	var sectionCfml  = $root.data( "sectionCfml" ) || "CFML frames:";
	var sectionJava  = $root.data( "sectionJava" ) || "Java stack:";
	var framesNone   = $root.data( "framesNone" ) || "(none)";
	var showingActive = $root.data( "showingActive" ) || "{1} active CFML requests";
	var showingAll    = $root.data( "showingAll" ) || "{1} threads";

	var selectedThreads = function(){
		if ( !$activeOnly.is( ":checked" ) ) {
			return threads;
		}

		return $.grep( threads, function( thread ){
			return !!thread.activeCfml;
		} );
	};

	var formatCount = function( pattern, count ){
		return String( pattern ).replace( "{1}", count );
	};

	var renderDump = function( javaStack ){
		var shown   = selectedThreads();
		var pattern = $activeOnly.is( ":checked" ) ? showingActive : showingAll;
		var lines   = [
			  dump.capturedAt || ""
			, $activeOnly.is( ":checked" ) ? scopeActive : scopeAll
			, javaStack ? modeJava : modeCfml
			, formatCount( pattern, shown.length )
			, ""
		];

		$.each( shown, function( i, thread ){
			var frames = javaStack ? ( thread.javaStack || [] ) : ( thread.cfmlStack || [] );

			lines.push( '"' + thread.name + '" id=' + thread.id + " state=" + thread.state + " running=" + ( thread.elapsed || "" ) );
			if ( thread.primary ) {
				lines.push( "  " + thread.primary );
			}
			if ( thread.secondary ) {
				lines.push( "  " + thread.secondary );
			}
			lines.push( "  " + ( javaStack ? sectionJava : sectionCfml ) );
			if ( !frames.length ) {
				lines.push( "    " + framesNone );
			} else {
				$.each( frames, function( n, frame ){
					lines.push( javaStack ? ( "    at " + frame ) : ( "    " + frame ) );
				} );
			}
			lines.push( "" );
		} );

		return lines.join( "\n" );
	};

	var render = function(){
		var shown   = selectedThreads();
		var pattern = $activeOnly.is( ":checked" ) ? showingActive : showingAll;

		$text.text( renderDump( stackMode == "java" ) );
		$count.text( formatCount( pattern, shown.length ) );
	};

	$activeOnly.on( "change", render );

	$root.on( "click", ".threaddump-stack", function( e ){
		e.preventDefault();
		var $btn = $( this );

		stackMode = $btn.data( "stack" );
		$root.find( ".threaddump-stack" ).removeClass( "btn-info" ).addClass( "btn-default" );
		$btn.removeClass( "btn-default" ).addClass( "btn-info" );
		render();
	} );

	$root.on( "click", ".threaddump-copy", function( e ){
		e.preventDefault();
		var $btn = $( this );

		copyText( renderDump( $btn.data( "stack" ) == "java" ) ).done( function(){
			flashCopied( $btn );
		} );
	} );

	render();

} )( presideJQuery );
