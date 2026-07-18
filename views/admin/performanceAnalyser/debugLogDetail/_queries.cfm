<cfscript>
	queries          = args.queries ?: QueryNew( '' );
	slowThresholdNs  = Val( args.slowThresholdNs ?: ( 100 * 1000 * 1000 ) );
</cfscript>

<cfoutput>
	<div class="table-responsive">
		<table class="table table-striped static-data-table">
			<thead>
				<tr>
					<th style="min-width:8em;">#translateResource( "performanceanalyser:queries.th.time" )#</th>
					<th style="min-width:7em;">#translateResource( "performanceanalyser:queries.th.recordcount" )#</th>
					<th>#translateResource( "performanceanalyser:queries.th.sql" )#</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="queries">
					<tr class="#( Val( queries.exec_time ) gte slowThresholdNs ? 'warning' : '' )#">
						<td>#perfAnalyserPrettyTime( queries.exec_time )# ms</td>
						<td>#NumberFormat( queries.recordcount )#</td>
						<td><code style="white-space:pre-wrap;">#HtmlEditFormat( queries.sql )#</code></td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>
