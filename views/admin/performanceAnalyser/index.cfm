<cfscript>
	canControlAdmin  = isTrue( prc.canControlAdmin  ?: "" );
	debugSettings    = isTrue( prc.debugSettings    ?: "" );
	debuggingEnabled = isTrue( prc.debuggingEnabled ?: "" );
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
		<div class="alert alert-warning">
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
	</cfif>
</cfoutput>