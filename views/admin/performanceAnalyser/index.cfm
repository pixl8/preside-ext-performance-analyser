<cfscript>
	activeTab  = prc.tab ?: ""
	tabs       = prc.tabs ?: [];
	tabContent = prc.tabContent ?: "";
	baseLink   = event.buildAdminLink( linkto="performanceAnalyser", queryString="tab=${tab}" );
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<cfloop array="#tabs#" index="tab">
				<li<cfif tab eq activeTab> class="active"</cfif>>
					<a href="#replace( baselink, '${tab}', tab)#">
						<i class="fa fa-fw #translateResource( 'performanceAnalyser:tab.#tab#.iconClass' )#"></i>&nbsp;
						#translateResource( 'performanceAnalyser:tab.#tab#.title' )#
					</a>
				</li>
			</cfloop>
		</ul>

		<div class="tab-content">
			<div class="tab-pane active">
				#tabContent#
			</div>
		</div>
	</div>
</cfoutput>