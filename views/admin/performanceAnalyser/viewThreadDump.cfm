<cfscript>
	threadDump     = prc.threadDump ?: {};
	dumpText       = threadDump.dump_text ?: "";
	structuredDump = IsJSON( dumpText );
	listingLink    = event.buildAdminLink( linkto="performanceanalyser", querystring="tab=threaddumps" );
	safeDumpJson   = structuredDump ? Replace( dumpText, "<", "\u003c", "all" ) : "";
</cfscript>

<cfoutput>
	<div class="perf-analyser-threaddump"
		data-copied-label="#HtmlEditFormat( translateResource( 'performanceanalyser:threads.copied' ) )#"
		data-copy-cfml-label="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.copy.cfml' ) )#"
		data-copy-java-label="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.copy.java' ) )#"
		data-scope-active="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.scope.active' ) )#"
		data-scope-all="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.scope.all' ) )#"
		data-mode-cfml="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.stack.cfml' ) )#"
		data-mode-java="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.stack.java' ) )#"
		data-section-cfml="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.section.cfml' ) )#"
		data-section-java="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.section.java' ) )#"
		data-frames-none="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.frames.none' ) )#"
		data-showing-active="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.showing.active' ) )#"
		data-showing-all="#HtmlEditFormat( translateResource( 'performanceanalyser:threaddump.showing.all' ) )#"
	>
		<div class="clearfix" style="margin-bottom:1em;">
			<a href="#listingLink#" class="btn btn-sm btn-default">
				<i class="fa fa-reply"></i>
				#translateResource( "performanceanalyser:threaddump.back" )#
			</a>
			<cfif structuredDump>
				<button type="button" class="btn btn-sm btn-info threaddump-copy" data-stack="cfml">
					<i class="fa fa-copy"></i>
					<span class="threaddump-copy-label">#translateResource( "performanceanalyser:threaddump.copy.cfml" )#</span>
				</button>
				<button type="button" class="btn btn-sm btn-info threaddump-copy" data-stack="java">
					<i class="fa fa-copy"></i>
					<span class="threaddump-copy-label">#translateResource( "performanceanalyser:threaddump.copy.java" )#</span>
				</button>
			<cfelse>
				<button type="button" class="btn btn-sm btn-info" id="threaddump-copy-btn">
					<i class="fa fa-copy"></i>
					<span class="threaddump-copy-label">#translateResource( "performanceanalyser:threaddump.copy" )#</span>
				</button>
			</cfif>
			<span class="pull-right light-grey" id="threaddump-count">
				<cfif !structuredDump>
					#translateResource( uri="performanceanalyser:threaddump.thread.count", data=[ threadDump.thread_count ?: 0 ] )#
				</cfif>
			</span>
		</div>

		<cfif structuredDump>
			<div style="margin-bottom:1em;">
				<label class="checkbox-inline">
					<input type="checkbox" class="ace" id="threaddump-active-only" checked="checked">
					<span class="lbl"> #translateResource( "performanceanalyser:threaddump.filter.active" )#</span>
				</label>
				<div class="btn-group" style="margin-left:1em;">
					<button type="button" class="btn btn-sm btn-info threaddump-stack" data-stack="cfml">#translateResource( "performanceanalyser:threaddump.stack.cfml" )#</button>
					<button type="button" class="btn btn-sm btn-default threaddump-stack" data-stack="java">#translateResource( "performanceanalyser:threaddump.stack.java" )#</button>
				</div>
			</div>
			<script type="application/json" id="threaddump-data">#safeDumpJson#</script>
		</cfif>

		<pre id="threaddump-text" style="white-space:pre;overflow:auto;max-height:70vh;"><cfif !structuredDump>#HtmlEditFormat( dumpText )#</cfif></pre>
	</div>
</cfoutput>
