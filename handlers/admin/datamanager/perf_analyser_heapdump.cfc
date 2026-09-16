component {

	property name="heapDumpService" inject="heapDumpService";

	private string function buildListingLInk() {
		return event.buildAdminLink( linkto="performanceanalyser", querystring="tab=heapdumps" );
	}

	private function renderRecord() {
		setNextEvent( url=heapDumpService.getHeapDumpUrl( prc.recordId ) );
	}

	private void function preDeleteRecordAction( event, rc, prc, args={} ) {
		var records = args.records ?: QueryNew('');

		for( var record in records ) {
			heapDumpService.deleteDumpFile( record.filepath );
		}
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		args.actions = args.actions ?: [];
		for( var action in args.actions ) {
			if ( ( action.icon == "fa-eye" ) ) {
				action.icon = "fa-download";
			}
		}
	}
}