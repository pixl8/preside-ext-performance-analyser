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