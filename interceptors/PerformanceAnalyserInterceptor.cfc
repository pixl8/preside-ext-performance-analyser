component extends="coldbox.system.Interceptor" {

	property name="luceeDebuggingService" inject="delayedInjector:luceeDebuggingService";

	public void function configure() {}

	// public void function onRequestEnd( event ) {
	// 	luceeDebuggingService.get().log(
	// 		  pageUrl   = event.getCurrentUrl()
	// 		, adminuser = event.getAdminUserId()
	// 		, webuser   = getLoggedInUserId()
	// 	);
	// }

	// public void function postRunTaskManagerTask( event, interceptData ) {
	// 	luceeDebuggingService.get().log(
	// 		  pageUrl = interceptData.task.event ?: "-"
	// 		, type    = "task"
	// 	);
	// }

	// public void function postRunAdhocTask( event, interceptData ) {
	// 	luceeDebuggingService.get().log(
	// 		  pageUrl   = interceptData.task.event       ?: "-"
	// 		, adminuser = interceptData.task.admin_owner ?: ""
	// 		, webuser   = interceptData.task.web_owner   ?: ""
	// 		, type      = "adhoctask"
	// 	);
	// }
}
