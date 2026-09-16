<cfscript>
	snapshotUrl = args.snapshotUrl ?: "";
</cfscript>

<cfoutput>
	<div class="perf-analyser-threads" data-snapshot-url="#HtmlEditFormat( snapshotUrl )#">
		<div class="row" style="margin-bottom:1em;">
			<div class="col-md-8">
				<div class="btn-group" data-toggle="buttons">
					<label class="btn btn-sm btn-primary active">
						<input type="radio" name="threads-view-mode" value="preside" autocomplete="off" checked>
						#translateResource( "performanceanalyser:threads.view.preside" )#
					</label>
					<label class="btn btn-sm btn-primary">
						<input type="radio" name="threads-view-mode" value="plain" autocomplete="off">
						#translateResource( "performanceanalyser:threads.view.plain" )#
					</label>
				</div>
				<label class="checkbox-inline" style="margin-left:1em;">
					<input type="checkbox" class="ace" id="threads-autorefresh">
					<span class="lbl"> #translateResource( "performanceanalyser:threads.autorefresh" )#</span>
				</label>
				<button type="button" class="btn btn-sm btn-info" id="threads-refresh-btn" style="margin-left:0.5em;">
					<i class="fa fa-refresh"></i>
					#translateResource( "performanceanalyser:threads.refresh" )#
				</button>
			</div>
			<div class="col-md-4 text-right">
				<span class="light-grey" id="threads-captured-at"></span>
			</div>
		</div>

		<div class="row" style="margin-bottom:1em;">
			<div class="col-md-4">
				<input type="text" class="form-control" id="threads-filter-name" placeholder="#translateResource( 'performanceanalyser:threads.filter.name' )#">
			</div>
			<div class="col-md-3">
				<select class="form-control" id="threads-filter-state">
					<option value="">#translateResource( "performanceanalyser:threads.filter.state.all" )#</option>
				</select>
			</div>
			<div class="col-md-3">
				<label class="checkbox-inline">
					<input type="checkbox" class="ace" id="threads-filter-cfml">
					<span class="lbl"> #translateResource( "performanceanalyser:threads.filter.cfml" )#</span>
				</label>
			</div>
		</div>

		<div id="threads-summary" class="well well-sm" style="margin-bottom:1em;"></div>

		<div class="table-responsive">
			<table class="table table-striped table-condensed" id="threads-table">
				<thead>
					<tr>
						<th style="width:4em;"></th>
						<th>#translateResource( "performanceanalyser:threads.th.name" )#</th>
						<th style="min-width:8em;">#translateResource( "performanceanalyser:threads.th.state" )#</th>
						<th style="min-width:8em;">#translateResource( "performanceanalyser:threads.th.kind" )#</th>
						<th style="min-width:10em;">#translateResource( "performanceanalyser:threads.th.summary" )#</th>
						<th style="min-width:8em;" class="text-right">#translateResource( "performanceanalyser:threads.th.cpu" )#</th>
					</tr>
				</thead>
				<tbody id="threads-tbody">
					<tr>
						<td colspan="6" class="text-center light-grey">#translateResource( "performanceanalyser:threads.loading" )#</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>
</cfoutput>
