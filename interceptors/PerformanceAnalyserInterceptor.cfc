component extends="coldbox.system.Interceptor" {

	property name="luceeDebuggingService" inject="delayedInjector:luceeDebuggingService";

	public void function configure() {}

	public void function preProcess( event ) {
		luceeDebuggingService.get().applyRequestMonitoringOutput();
	}

	/**
	 * ColdBox end-of-request point (NOT Application.cfc onRequestEnd —
	 * that name is never announced as an interception state).
	 *
	 * Scheduled taskmanager tasks run via private runEvent without
	 * prepostExempt, so they hit this point too. Adhoc tasks use
	 * prepostExempt=true and are not captured here.
	 */
	public void function postProcess( event ) {
		try {
			var type      = "http";
			var pageUrl   = event.getCurrentUrl();
			var adminUser = event.getAdminUserId();
			var webUser   = _safeWebUserId();

			if ( Len( event.getValue( name="_runningAdhocTaskId", defaultValue="", private=true ) ) ) {
				type    = "adhoctask";
				pageUrl = event.getCurrentEvent();
			} else if ( event.isBackgroundThread() ) {
				type    = "task";
				pageUrl = event.getCurrentEvent();
			}

			luceeDebuggingService.get().log(
				  pageUrl   = pageUrl
				, adminuser = adminUser
				, webuser   = webUser
				, type      = type
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
