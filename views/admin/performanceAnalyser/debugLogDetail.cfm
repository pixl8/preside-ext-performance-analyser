<cfscript>
	detail = prc.debugLogDetail ?: {};
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li class="active">
				<a data-toggle="tab" href="##exectimes">
					<i class="fa fa-fw fa-clock-o"></i>&nbsp;
					#translateResource( 'performanceAnalyser:page.debuglog.detail.execttimes.tab' )#
				</a>
			</li>
			<li>
				<a data-toggle="tab" href="##queries">
					<i class="fa fa-fw fa-database"></i>&nbsp;
					#translateResource( uri='performanceAnalyser:page.debuglog.detail.queries.tab', data=[ detail.queries.recordCount ] )#
				</a>
			</li>
		</ul>

		<div class="tab-content">
			<div class="tab-pane active" id="exectimes">
				#renderView( view="/admin/performanceAnalyser/debugLogDetail/_executionTimes", args=detail )#
			</div>
			<div class="tab-pane" id="queries">
				#renderView( view="/admin/performanceAnalyser/debugLogDetail/_queries", args=detail )#
			</div>
		</div>
	</div>
</cfoutput>