<cffunction name="perfAnalyserPrettyTime" access="public" returntype="any" output="false">
	<cfargument name="n" type="numeric" required="true"  />
	<cfscript>
		if ( arguments.n == 0 ) {
			return 0;
		}

		 var s = arguments.n / ( 1000 * 1000 );
		 if ( int( s ) eq 0 ) {
		 	return LsNumberFormat( s, "0.00" );
		 }

		return LsNumberFormat( s, "0" );
	</cfscript>
</cffunction>

<cffunction name="perfAnalyserPrettySrc" access="public" returntype="string" output="false">
	<cfargument name="templatePath" type="string" required="true" />
	<cfargument name="methodName"   type="string" required="false" default="-" />
	<cfscript>
		var src = arguments.templatePath;

		src = ReReplaceNoCase( src, "^.*?[/\\]website[/\\]", "" );
		src = ReReplaceNoCase( src, "^.*?[/\\]application[/\\]", "application/" );
		src = Replace( src, "\", "/", "all" );

		if ( Len( Trim( arguments.methodName ) ) && arguments.methodName != "-" ) {
			return src & " $" & arguments.methodName;
		}

		return src;
	</cfscript>
</cffunction>

<cffunction name="perfAnalyserPrettyBytes" access="public" returntype="string" output="false">
	<cfargument name="bytes" type="numeric" required="true" />
	<cfscript>
		var amount = arguments.bytes;

		if ( amount < 0 ) {
			amount = 0;
		}
		if ( amount < 1024 ) {
			return LsNumberFormat( amount, "0" ) & " B";
		}
		if ( amount < ( 1024 * 1024 ) ) {
			return LsNumberFormat( amount / 1024, "0.0" ) & " KB";
		}
		if ( amount < ( 1024 * 1024 * 1024 ) ) {
			return LsNumberFormat( amount / ( 1024 * 1024 ), "0.00" ) & " MB";
		}

		return LsNumberFormat( amount / ( 1024 * 1024 * 1024 ), "0.00" ) & " GB";
	</cfscript>
</cffunction>

<cffunction name="perfAnalyserSortAllocNodes" access="public" returntype="array" output="false">
	<cfargument name="nodes" type="array" required="true" />
	<cfscript>
		ArraySort( arguments.nodes, function( a, b ) {
			return Val( b.inclusive ?: 0 ) - Val( a.inclusive ?: 0 );
		} );

		for ( var node in arguments.nodes ) {
			if ( IsArray( node.children ?: "" ) && ArrayLen( node.children ) ) {
				perfAnalyserSortAllocNodes( node.children );
			}
		}

		return arguments.nodes;
	</cfscript>
</cffunction>

<cffunction name="perfAnalyserRenderAllocNodes" access="public" returntype="string" output="false">
	<cfargument name="nodes"       type="array"   required="true" />
	<cfargument name="parentBytes" type="numeric" required="true" />
	<cfargument name="ownBytes"    type="numeric" required="false" default="0" />
	<cfargument name="openFirst"   type="boolean" required="false" default="false" />
	<cfargument name="depth"       type="numeric" required="false" default="0" />
	<cfargument name="parentId"    type="string"  required="false" default="" />
	<cfargument name="visible"     type="boolean" required="false" default="true" />
	<cfargument name="ids"         type="struct"  required="false" />
	<cfscript>
		var rows   = [];
		var html   = "";
		var opened = false;

		if ( !StructKeyExists( arguments, "ids" ) || !IsStruct( arguments.ids ) ) {
			arguments.ids = { n = 0 };
		}

		for ( var node in arguments.nodes ) {
			ArrayAppend( rows, node );
		}

		if ( Val( arguments.ownBytes ) > 0 && ArrayLen( arguments.nodes ) ) {
			ArrayAppend( rows, {
				  own       = true
				, inclusive = Val( arguments.ownBytes )
				, kind      = ""
				, name      = ""
				, children  = []
			} );
		}

		ArraySort( rows, function( a, b ) {
			return Val( b.inclusive ?: 0 ) - Val( a.inclusive ?: 0 );
		} );

		for ( var row in rows ) {
			arguments.ids.n++;

			var nodeId    = arguments.ids.n;
			var inclusive = Val( row.inclusive ?: 0 );
			var share     = arguments.parentBytes ? ( inclusive / arguments.parentBytes * 100 ) : 0;
			var isOwn     = StructKeyExists( row, "own" ) && row.own;
			var kind      = LCase( row.kind ?: "" );
			var children  = row.children ?: [];
			var hasKids   = !isOwn && ArrayLen( children );
			var nodeOpen  = false;
			var pad       = 8 + ( arguments.depth * 16 );
			var hidden    = arguments.visible ? "" : " hidden";
			var pathHtml  = "";
			var countHtml = "";
			var typeHtml  = "";
			var rowClass  = isOwn ? "perf-alloc-own" : "";

			if ( isOwn ) {
				pathHtml = '<span class="perf-alloc-spacer"></span>' & perfAnalyserAllocKindIcon( "own" ) & '<span class="perf-alloc-label">' & HtmlEditFormat( translateResource( uri="performanceanalyser:allocation.tree.own", defaultValue="In this frame" ) ) & '</span>';
			} else {
				var kindLabel = translateResource( uri="performanceanalyser:allocation.kind.#kind#", defaultValue=kind );
				var iconHtml  = perfAnalyserAllocKindIcon( kind );
				var nameHtml  = '<span class="perf-alloc-label" title="' & HtmlEditFormat( row.name ?: "" ) & '">' & HtmlEditFormat( row.name ?: "" ) & '</span>';

				countHtml = Val( row.callCount ?: 0 ) ? NumberFormat( row.callCount ) : "";
				typeHtml  = HtmlEditFormat( kindLabel );

				if ( hasKids ) {
					nodeOpen = arguments.openFirst && !opened;
					opened   = true;
					pathHtml = '<button type="button" class="perf-alloc-toggle" aria-expanded="' & ( nodeOpen ? "true" : "false" ) & '"></button>' & iconHtml & nameHtml;
					if ( nodeOpen ) {
						rowClass = Trim( rowClass & " is-open" );
					}
				} else {
					pathHtml = '<span class="perf-alloc-spacer"></span>' & iconHtml & nameHtml;
				}
			}

			html &= '<tr class="' & rowClass & '" data-node="' & nodeId & '" data-parent="' & HtmlEditFormat( arguments.parentId ) & '"' & hidden;
			if ( !hasKids && !isOwn ) {
				html &= ' title="' & HtmlEditFormat( translateResource( uri="performanceanalyser:allocation.tree.leaf", defaultValue="No nested views or viewlets were rendered inside this frame." ) ) & '"';
			}
			html &= '>';
			html &= '<td class="perf-alloc-path" style="padding-left:' & pad & 'px">' & pathHtml & '</td>';
			html &= '<td class="perf-alloc-num">' & countHtml & '</td>';
			html &= '<td class="perf-alloc-type">' & typeHtml & '</td>';
			html &= '<td class="perf-alloc-num">' & perfAnalyserPrettyBytes( inclusive ) & '</td>';
			html &= '<td class="perf-alloc-num">' & LsNumberFormat( share, "0.0" ) & '%</td>';
			html &= '</tr>';

			if ( hasKids ) {
				html &= perfAnalyserRenderAllocNodes(
					  nodes       = children
					, parentBytes = inclusive
					, ownBytes    = Val( row.exclusive ?: 0 )
					, depth       = arguments.depth + 1
					, parentId    = nodeId
					, visible     = nodeOpen
					, ids         = arguments.ids
				);
			}
		}

		return html;
	</cfscript>
</cffunction>

<cffunction name="perfAnalyserAllocKindIcon" access="public" returntype="string" output="false">
	<cfargument name="kind" type="string" required="true" />
	<cfscript>
		var icons = {
			  event      = "fa-bolt"
			, view       = "fa-file-o"
			, viewlet    = "fa-puzzle-piece"
			, layout     = "fa-columns"
			, select     = "fa-database"
			, renderdata = "fa-exchange"
			, own        = "fa-circle-o"
		};
		var icon = icons[ LCase( arguments.kind ) ] ?: "fa-circle-o";

		return '<i class="fa fa-fw #icon# perf-alloc-kind-icon" aria-hidden="true"></i>';
	</cfscript>
</cffunction>

<cffunction name="perfAnalyserWidgetBox" access="public" returntype="string" output="false">
	<cfargument name="title" type="string" required="true" />
	<cfargument name="icon" type="string" required="true" />
	<cfargument name="body" type="string" required="true" />

	<cfscript>
		return '<div class="widget-box">
				<div class="widget-header">
					<h4 class="widget-title lighter smaller">
						<i class="fa fa-fw #arguments.icon#"></i>
						<span>#arguments.title#</span>
					</h4>
				</div>

				<div class="widget-body">
					<div class="widget-main padding-20">
						#arguments.body#
					</div>
				</div>
			</div>';
	</cfscript>
</cffunction>
