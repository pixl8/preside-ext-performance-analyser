<cfscript>
	canControlAdmin  = isTrue( prc.canControlAdmin  ?: "" );
	debuggingEnabled = isTrue( args.debuggingEnabled ?: "" );
	logId            = rc.logId ?: "";
	debugLogs        = args.debugLogs ?: [];
	baseViewLogLink  = event.buildAdminLink( linkto="performanceAnalyser.debuglogDetail", queryString="logid={id}" );
</cfscript>

<cfoutput>
	<cfif !canControlAdmin>
		<div class="alert alert-danger">
			<p><strong>
				<i class="fa fa-fw fa-exclamation-triangle"></i>
				#translateResource( "performanceanalyser:admin.access.denied.title" )#
			</strong></p>
			<p>#translateResource( "performanceanalyser:admin.access.denied.description" )#</p>
		</div>
	<cfelseif !debuggingEnabled>
		<div class="alert alert-success">
			<p><strong>
				<i class="fa fa-fw fa-exclamation-triangle"></i>
				#translateResource( "performanceanalyser:debugging.disabled.title" )#
			</strong></p>
			<p>#translateResource( "performanceanalyser:debugging.disabled.description" )#</p>
		</div>
	<cfelse>
		<div class="alert alert-warning">
			<p><strong>
				<i class="fa fa-fw fa-info-circle"></i>
				#translateResource( "performanceanalyser:debugging.enabled.title" )#
			</strong></p>
			<p>#translateResource( "performanceanalyser:debugging.enabled.description" )#</p>
		</div>

		#objectDataTable( "perfanalyser_req_log" )#

		<!--- <div class="table-responsive">
			<table class="table table-striped static-data-table">
				<thead>
					<tr>
						<th style="min-width:10em;">#translateResource( "performanceAnalyser:log.summary.th.starttime" )#</th>
						<th>#translateResource( "performanceAnalyser:log.summary.th.pageinfo" )#</th>
						<th style="min-width:10em;">#translateResource( "performanceAnalyser:log.summary.th.querycount" )#</th>
						<th style="min-width:10em;">#translateResource( "performanceAnalyser:log.summary.th.exectime" )#</th>
						<th style="min-width:5em;">&nbsp;</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#debugLogs#" item="l">
						<tr class="clickable">
							<td>#DateTimeFormat( l.started, 'hh:nn:ss' )#</td>
							<td>
								<cfif Len( l.url )>
									<span class="grey">#ListFirst( l.url, "?" )#</span>
									<cfif ListLen( l.url, "?" ) gt 1>
										<br>
										<small class="light-grey">?#ListRest( l.url, "?" )#</small>
									</cfif>
								<cfelse>
									<em class="light-grey">?</em>
								</cfif>
							</td>
							<td>#NumberFormat( l.queries )#</td>
							<td>#perfAnalyserPrettyTime( l.exectime )# ms</td>
							<td>
								<a href="#replace( baseViewLogLink, '{id}', l.id )#">
									<i class="fa fa-fw fa-search"></i>
								</a>
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div> --->
	</cfif>
</cfoutput>