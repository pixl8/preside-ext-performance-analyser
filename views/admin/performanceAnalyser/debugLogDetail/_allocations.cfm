<cfscript>
	allocs         = args.allocs ?: QueryNew( "" );
	exclusiveTotal = 0;
	nodesByHash    = {};
	allocRoots     = [];
	hasHierarchy   = ListFindNoCase( allocs.columnList ?: "", "path_hash" );

	for ( var alloc in allocs ) {
		var bytes = Val( alloc.exclusive_bytes ?: 0 );
		var kind  = LCase( alloc.kind ?: "" );

		exclusiveTotal += bytes;

		if ( hasHierarchy && Len( alloc.path_hash ?: "" ) ) {
			nodesByHash[ alloc.path_hash ] = {
				  kind       = kind
				, name       = alloc.name ?: ""
				, inclusive  = Val( alloc.inclusive_bytes ?: 0 )
				, exclusive  = bytes
				, callCount  = Val( alloc.call_count ?: 0 )
				, parentHash = ( alloc.parent_hash ?: "" ) == "-" ? "" : ( alloc.parent_hash ?: "" )
				, children   = []
			};
		}
	}

	for ( var pathHash in nodesByHash ) {
		var node   = nodesByHash[ pathHash ];
		var parent = Len( node.parentHash ) ? ( nodesByHash[ node.parentHash ] ?: "" ) : "";

		if ( IsStruct( parent ) && node.parentHash != pathHash ) {
			ArrayAppend( parent.children, node );
		} else {
			ArrayAppend( allocRoots, node );
		}
	}

	if ( ArrayLen( allocRoots ) ) {
		perfAnalyserSortAllocNodes( allocRoots );
	}
</cfscript>

<cfoutput>
	<style>
		.perf-alloc-tree {
			width         : 100%;
			margin-bottom : 16px;
			table-layout  : fixed;
		}
		.perf-alloc-tree th {
			font-size     : 12px;
			font-weight   : 600;
			color         : ##888;
			border-bottom : 1px solid ##e5e5e5;
			padding       : 4px 8px;
		}
		.perf-alloc-tree td {
			padding        : 8px;
			border-bottom  : 1px solid ##f3f3f3;
			vertical-align : baseline;
		}
		.perf-alloc-tree tr[hidden] {
			display : none;
		}
		.perf-alloc-tree .perf-alloc-col-count { width : 5em; }
		.perf-alloc-tree .perf-alloc-col-type { width : 6.5em; }
		.perf-alloc-tree .perf-alloc-col-memory { width : 8.5em; }
		.perf-alloc-tree .perf-alloc-col-percent { width : 5em; }
		.perf-alloc-tree .perf-alloc-num {
			text-align    : right;
			white-space   : nowrap;
			font-variant-numeric : tabular-nums;
		}
		.perf-alloc-tree .perf-alloc-type {
			color       : ##999;
			white-space : nowrap;
		}
		.perf-alloc-tree .perf-alloc-path {
			overflow      : hidden;
			text-overflow : ellipsis;
			white-space   : nowrap;
		}
		.perf-alloc-tree .perf-alloc-toggle,
		.perf-alloc-tree .perf-alloc-spacer {
			display      : inline-block;
			width        : 1.1em;
			margin-right : 4px;
			padding      : 0;
			border       : 0;
			background   : none;
			color        : ##999;
			text-align   : center;
			line-height  : 1;
		}
		.perf-alloc-tree .perf-alloc-kind-icon {
			margin-right : 6px;
			color        : ##999;
			vertical-align : baseline;
		}
		.perf-alloc-tree tr:has( .perf-alloc-toggle ) .perf-alloc-label,
		.perf-alloc-tree .perf-alloc-toggle {
			cursor : pointer;
		}
		.perf-alloc-tree .perf-alloc-toggle::before {
			content : "▸";
		}
		.perf-alloc-tree tr.is-open > .perf-alloc-path .perf-alloc-toggle::before {
			content : "▾";
		}
		.perf-alloc-tree .perf-alloc-own .perf-alloc-label {
			color : ##999;
		}
	</style>

	<cfif !allocs.recordCount>
		<p class="text-muted"><em>#translateResource( "performanceanalyser:allocation.summary.empty" )#</em></p>
	<cfelse>
		<div class="alert alert-info">
			<i class="fa fa-fw fa-info-circle"></i>
			#translateResource( uri="performanceanalyser:allocation.tree.intro", defaultValue="Each row is an event, viewlet, view, layout, selectData call or renderData call that ran during the request. Memory used is everything allocated on the request thread while that frame was running, including nested calls. The percentage is its share of the parent row. In this frame is the part allocated by the frame itself. This is allocation during the request, not memory still held afterwards." )#
		</div>
		<cfif ArrayLen( allocRoots )>
			<table class="perf-alloc-tree">
				<thead>
					<tr>
						<th>#translateResource( uri="performanceanalyser:allocation.tree.col.path", defaultValue="Path" )#</th>
						<th class="perf-alloc-num perf-alloc-col-count">#translateResource( uri="performanceanalyser:allocation.tree.col.count", defaultValue="Count" )#</th>
						<th class="perf-alloc-col-type">#translateResource( uri="performanceanalyser:allocation.tree.col.type", defaultValue="Type" )#</th>
						<th class="perf-alloc-num perf-alloc-col-memory">#translateResource( uri="performanceanalyser:allocation.tree.col.memory", defaultValue="Memory used" )#</th>
						<th class="perf-alloc-num perf-alloc-col-percent">#translateResource( uri="performanceanalyser:allocation.tree.col.percent", defaultValue="%" )#</th>
					</tr>
				</thead>
				<tbody>
					#perfAnalyserRenderAllocNodes(
						  nodes       = allocRoots
						, parentBytes = exclusiveTotal
						, openFirst   = true
					)#
				</tbody>
			</table>
			<script>
				( function() {
					var tree = document.currentScript.previousElementSibling;

					if ( !tree ) {
						return;
					}

					tree.addEventListener( "click", function( event ) {
						var hit = event.target.closest( ".perf-alloc-toggle, .perf-alloc-label" );

						if ( !hit || !tree.contains( hit ) ) {
							return;
						}

						var row = hit.closest( "tr" );

						if ( !row || !row.querySelector( ".perf-alloc-toggle" ) ) {
							return;
						}

						setBranch( row.getAttribute( "data-node" ), !row.classList.contains( "is-open" ) );
					} );

					function setBranch( id, open ) {
						var row = tree.querySelector( 'tr[data-node="' + id + '"]' );
						var children = tree.querySelectorAll( 'tr[data-parent="' + id + '"]' );
						var i = 0;

						if ( !row ) {
							return;
						}

						row.classList.toggle( "is-open", open );
						var toggle = row.querySelector( ".perf-alloc-toggle" );

						if ( toggle ) {
							toggle.setAttribute( "aria-expanded", open ? "true" : "false" );
						}

						for ( i = 0; i < children.length; i++ ) {
							children[ i ].hidden = !open;

							if ( !open && children[ i ].getAttribute( "data-node" ) ) {
								setBranch( children[ i ].getAttribute( "data-node" ), false );
							}
						}
					}
				} )();
			</script>
		<cfelse>
			<p class="text-muted"><em>#translateResource( "performanceanalyser:allocation.tree.legacy" )#</em></p>
		</cfif>

	</cfif>
</cfoutput>
