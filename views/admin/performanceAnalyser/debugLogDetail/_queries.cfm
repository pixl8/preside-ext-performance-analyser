<cfscript>
	queries = args.queries ?: QueryNew( '' );
</cfscript>

<cfoutput>
	<div class="table-responsive">
		<table class="table table-striped static-data-table">
			<thead>
				<tr>
					<th style="min-width:12em;">#translateResource( "performanceanalyser:queries.th.time" )#</th>
					<th>#translateResource( "performanceanalyser:queries.th.sql" )#</th>
					<th style="min-width:10em;">#translateResource( "performanceanalyser:queries.th.recordcount" )#</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="queries">
					<tr>
						<td>#perfAnalyserPrettyTime( queries.time   )#</td>
						<td>#queries.sql#</td>
						<td>#LsNumberFormat( queries.count )#</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>