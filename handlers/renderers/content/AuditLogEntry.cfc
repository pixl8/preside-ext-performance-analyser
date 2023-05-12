component {

	private string function performanceanalyser( event, rc, prc, args={} ) {
		var action   = args.action            ?: "";
		var known_as = args.known_as          ?: "";
		var userLink = args.userLink          ?: "";
		var userLink = '<a href="#args.userLink#">#args.known_as#</a>';

		return translateResource( uri="auditlog.performanceanalyser:#args.action#.message", data=[ userLink ] );
	}

}