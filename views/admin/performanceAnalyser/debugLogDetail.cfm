<cfscript>
	detail           = prc.debugLogDetail ?: {};
	queryCount       = IsQuery( detail.queries ?: "" ) ? detail.queries.recordCount : 0;
	execCount        = IsQuery( detail.execs   ?: "" ) ? detail.execs.recordCount   : 0;
	slowThresholdNs  = 100 * 1000 * 1000; // 100ms
</cfscript>

<cfoutput>
	<div class="well well-sm">
		<dl class="dl-horizontal" style="margin-bottom:0;">
			<dt>#translateResource( "performanceanalyser:detail.summary.type" )#</dt>
			<dd>#translateResource( uri="enum.luceeDebugRequestTypes:#( detail.type ?: 'http' )#.label", defaultValue=detail.type ?: "" )#</dd>

			<dt>#translateResource( "performanceanalyser:detail.summary.url" )#</dt>
			<dd><code>#HtmlEditFormat( detail.url ?: "" )#</code></dd>

			<dt>#translateResource( "performanceanalyser:detail.summary.when" )#</dt>
			<dd>#DateTimeFormat( detail.datecreated ?: Now(), "yyyy-mm-dd HH:nn:ss" )#</dd>

			<dt>#translateResource( "performanceanalyser:detail.summary.total" )#</dt>
			<dd>#perfAnalyserPrettyTime( Val( detail.total_time ?: 0 ) )# ms</dd>

			<dt>#translateResource( "performanceanalyser:detail.summary.querytime" )#</dt>
			<dd>#perfAnalyserPrettyTime( Val( detail.query_time ?: 0 ) )# ms (#NumberFormat( Val( detail.query_count ?: queryCount ) )# #translateResource( "performanceanalyser:detail.summary.queries" )#)</dd>

			<cfif Len( detail.admin_user ?: "" )>
				<dt>#translateResource( "performanceanalyser:detail.summary.adminuser" )#</dt>
				<dd>#renderLabel( "security_user", detail.admin_user )#</dd>
			</cfif>
			<cfif Len( detail.web_user ?: "" ) && isFeatureEnabled( "websiteUsers" )>
				<dt>#translateResource( "performanceanalyser:detail.summary.webuser" )#</dt>
				<dd>#renderLabel( "website_user", detail.web_user )#</dd>
			</cfif>
		</dl>
	</div>

	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li class="active">
				<a data-toggle="tab" href="##exectimes">
					<i class="fa fa-fw fa-clock-o"></i>&nbsp;
					#translateResource( uri="performanceanalyser:page.debuglog.detail.execttimes.tab.count", data=[ execCount ] )#
				</a>
			</li>
			<li>
				<a data-toggle="tab" href="##queries">
					<i class="fa fa-fw fa-database"></i>&nbsp;
					#translateResource( uri="performanceanalyser:page.debuglog.detail.queries.tab", data=[ queryCount ] )#
				</a>
			</li>
		</ul>

		<div class="tab-content">
			<div class="tab-pane active" id="exectimes">
				#renderView( view="/admin/performanceAnalyser/debugLogDetail/_executionTimes", args={ execs=detail.execs ?: QueryNew( '' ), slowThresholdNs=slowThresholdNs } )#
			</div>
			<div class="tab-pane" id="queries">
				#renderView( view="/admin/performanceAnalyser/debugLogDetail/_queries", args={ queries=detail.queries ?: QueryNew( '' ), slowThresholdNs=slowThresholdNs } )#
			</div>
		</div>
	</div>
</cfoutput>
