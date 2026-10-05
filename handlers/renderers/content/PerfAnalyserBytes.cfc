component {

	private string function default( event, rc, prc, args={} ) {
		return perfAnalyserPrettyBytes( Val( args.data ?: 0 ) );
	}

}
