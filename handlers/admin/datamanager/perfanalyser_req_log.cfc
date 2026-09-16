component {

	private string function buildListingLink() {
		return event.buildAdminLink( linkto="performanceanalyser", querystring="tab=debugger" );
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink(
			  linkto      = "performanceanalyser.debugLogDetail"
			, queryString = "logId=#args.recordId#"
		);
	}

	private void function renderRecord() {
		setNextEvent( url=event.buildAdminLink(
			  linkto      = "performanceanalyser.debugLogDetail"
			, queryString = "logId=#prc.recordId#"
		) );
	}

}
