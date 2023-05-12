component {
	this.name = "Preside Performance Analyser Test Suite";

	this.mappings[ '/tests'   ] = ExpandPath( "/" );
	this.mappings[ '/testbox' ] = ExpandPath( "/testbox" );
	this.mappings[ '/performance-analyser'  ] = ExpandPath( "../" );

	setting requesttimeout=60000;
}
