component {

	property name="luceeDebuggingService" inject="luceeDebuggingService";

	/**
	 * Deletes old debug logs from the database
	 *
	 * @schedule     0 0 *\/1 * * *
	 * @displayName  Cleanup debug logs
	 * @displayGroup Cleanup
	 */
	private boolean function cleanupPerformanceAnalyserLogs( logger ) {
		return luceeDebuggingService.cleanupOldLogs( logger=arguments.logger ?: NullValue() );
	}

}