<cfscript>
	execs            = args.execs ?: QueryNew( '' );
	slowThresholdNs  = Val( args.slowThresholdNs ?: ( 100 * 1000 * 1000 ) );
</cfscript>

<cfoutput>
	<div class="table-responsive">
		<table class="table table-striped static-data-table">
			<thead>
				<tr>
					<th style="min-width:6em;">#translateResource( "performanceanalyser:exectimes.th.count" )#</th>
					<th style="min-width:7em;">#translateResource( "performanceanalyser:exectimes.th.min"   )#</th>
					<th style="min-width:7em;">#translateResource( "performanceanalyser:exectimes.th.max"   )#</th>
					<th style="min-width:7em;">#translateResource( "performanceanalyser:exectimes.th.avg"   )#</th>
					<th style="min-width:7em;">#translateResource( "performanceanalyser:exectimes.th.total" )#</th>
					<th>#translateResource( "performanceanalyser:exectimes.th.src" )#</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="execs">
					<tr class="#( Val( execs.total_time ) gte slowThresholdNs ? 'warning' : '' )#">
						<td>#NumberFormat( execs.call_count )#</td>
						<td>#perfAnalyserPrettyTime( execs.min_time  )# ms</td>
						<td>#perfAnalyserPrettyTime( execs.max_time  )# ms</td>
						<td>#perfAnalyserPrettyTime( execs.mean_time )# ms</td>
						<td>#perfAnalyserPrettyTime( execs.total_time )# ms</td>
						<td>
							<code>#HtmlEditFormat( perfAnalyserPrettySrc( execs.template_path, execs.method_name ) )#</code>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>
