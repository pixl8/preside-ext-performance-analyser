component extends="coldbox.system.Interceptor" {

	property name="luceeDebuggingService" inject="delayedInjector:luceeDebuggingService";

	public void function configure() {}

	public void function preProcess( event ) {
		luceeDebuggingService.get().applyRequestMonitoringOutput();
	}

	/**
	 * ColdBox end-of-request point (NOT Application.cfc onRequestEnd —
	 * that name is never announced as an interception state).
	 */
	public void function postProcess( event ) {
		try {
			luceeDebuggingService.get().log(
				  pageUrl   = event.getCurrentUrl()
				, adminuser = event.getAdminUserId()
				, webuser   = _safeWebUserId()
			);
		} catch ( any e ) {
			writeLog(
				  type = "error"
				, file = "performanceanalyser"
				, text = "Failed to persist debug log: #e.message# | #e.detail# | #e.stacktrace#"
			);
		}
	}

	private string function _safeWebUserId() {
		try {
			return getLoggedInUserId();
		} catch ( any e ) {
			return "";
		}
	}
}
