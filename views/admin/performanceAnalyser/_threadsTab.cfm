<cfscript>
	snapshotUrl = args.snapshotUrl ?: "";
</cfscript>

<cfoutput>
	<div class="perf-analyser-threads" data-snapshot-url="#HtmlEditFormat( snapshotUrl )#" data-copy-label="#HtmlEditFormat( translateResource( 'performanceanalyser:threads.copy' ) )#" data-copied-label="#HtmlEditFormat( translateResource( 'performanceanalyser:threads.copied' ) )#">
		<p class="light-grey">#translateResource( "performanceanalyser:threads.intro" )#</p>

		<style>
			.threads-toolbar {
				display         : flex;
				align-items     : center;
				justify-content : space-between;
				margin-bottom   : 1em;
			}
			.threads-toolbar-controls {
				display     : flex;
				align-items : center;
			}
			.threads-toolbar .checkbox-inline {
				padding-top : 0;
			}
			.threads-toolbar .threads-refresh-rate {
				display        : inline-block;
				width          : auto;
				margin-left    : 0.75em;
				vertical-align : middle;
			}
			.threads-toolbar .threads-refresh-unit {
				margin-left : 0.35em;
			}
			.threads-toolbar ##threads-refresh-btn {
				margin-left    : 0.75em;
				vertical-align : middle;
			}
			.thread-identity {
				display     : flex;
				align-items : flex-start;
			}
			.perf-analyser-threads .thread-identity .thread-toggle,
			.perf-analyser-threads .thread-identity .thread-identity-icon {
				display         : flex;
				align-items     : center;
				justify-content : center;
				flex            : 0 0 auto;
				height          : 1.4286em;
				margin          : 0;
				padding         : 0;
				line-height     : 1;
				border          : 0;
			}
			.perf-analyser-threads .thread-identity .thread-toggle {
				width        : 1.15em;
				margin-right : 0.15em;
			}
			.perf-analyser-threads .thread-identity .thread-identity-icon {
				width        : 1.25em;
				margin-right : 0.4em;
			}
			.thread-identity .thread-identity-text {
				min-width : 0;
			}
		</style>

		<div class="threads-toolbar">
			<div class="threads-toolbar-controls">
				<label class="checkbox-inline">
					<input type="checkbox" class="ace" id="threads-autorefresh">
					<span class="lbl"> #translateResource( "performanceanalyser:threads.autorefresh" )#</span>
				</label>
				<select id="threads-refresh-rate" class="form-control input-sm threads-refresh-rate">
					<option value="1">1</option>
					<option value="2">2</option>
					<option value="3">3</option>
					<option value="5" selected>5</option>
					<option value="10">10</option>
				</select>
				<span class="light-grey threads-refresh-unit">#translateResource( "performanceanalyser:threads.refresh.seconds" )#</span>
				<button type="button" class="btn btn-sm btn-info" id="threads-refresh-btn">
					<i class="fa fa-refresh"></i>
					#translateResource( "performanceanalyser:threads.refresh" )#
				</button>
			</div>
			<span class="light-grey" id="threads-captured-at"></span>
		</div>

		<div class="table-responsive">
			<table class="table table-striped table-condensed" id="threads-table">
				<thead>
					<tr>
						<th>#translateResource( "performanceanalyser:threads.th.request" )#</th>
						<th>#translateResource( "performanceanalyser:threads.th.name" )#</th>
						<th style="min-width:8em;">#translateResource( "performanceanalyser:threads.th.state" )#</th>
						<th style="min-width:8em;" class="text-right">#translateResource( "performanceanalyser:threads.th.running" )#</th>
						<th style="width:4em;"></th>
					</tr>
				</thead>
				<tbody id="threads-tbody">
					<tr>
						<td colspan="5" class="text-center light-grey">#translateResource( "performanceanalyser:threads.loading" )#</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>
</cfoutput>
