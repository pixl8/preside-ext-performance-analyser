component {

	private string function buildListingLink() {
		return event.buildAdminLink( linkto="performanceanalyser", querystring="tab=threaddumps" );
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkto="performanceanalyser.viewThreadDump", querystring="id=" & ( args.recordId ?: "" ) );
	}

}
