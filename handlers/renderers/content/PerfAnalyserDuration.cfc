component {

	private string function default( event, rc, prc, args={} ) {
		var ms = perfAnalyserPrettyTime( Val( args.data ?: 0 ) );

		return "#ms# ms";
	}

}
