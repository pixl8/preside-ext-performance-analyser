<cfscript>
	pages = args.pages ?: QueryNew( '' );
</cfscript>

<cfoutput>
	<div class="table-responsive">
		<table class="table table-striped static-data-table">
			<thead>
				<tr>
					<th style="min-width:8em;">#translateResource( "performanceanalyser:exectimes.th.count" )#</th>
					<th style="min-width:8em;">#translateResource( "performanceanalyser:exectimes.th.min"   )#</th>
					<th style="min-width:8em;">#translateResource( "performanceanalyser:exectimes.th.max"   )#</th>
					<th style="min-width:8em;">#translateResource( "performanceanalyser:exectimes.th.avg"   )#</th>
					<th style="min-width:8em;">#translateResource( "performanceanalyser:exectimes.th.total" )#</th>
					<th>#translateResource( "performanceanalyser:exectimes.th.src"   )#</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="pages">
					<tr>
						<td>#pages.count#</td>
						<td>#perfAnalyserPrettyTime( pages.min   )#</td>
						<td>#perfAnalyserPrettyTime( pages.max   )#</td>
						<td>#perfAnalyserPrettyTime( pages.avg   )#</td>
						<td>#int( pages.total )#</td>
						<td>#pages.src#</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>