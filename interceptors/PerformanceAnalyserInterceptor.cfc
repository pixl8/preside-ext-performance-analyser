component extends="coldbox.system.Interceptor" {

	property name="luceeDebuggingService"   inject="delayedInjector:luceeDebuggingService";
	property name="allocationSampler"        inject="delayedInjector:allocationSampler";
	property name="presideObjectService"     inject="delayedInjector:presideObjectService";
	property name="activeRequestTracker"     inject="delayedInjector:activeRequestTracker";

	public void function configure() {
		variables.frameKey       = "_perfAllocFrame";
		variables.viewletWrapped = false;
		variables.selectWrapped  = false;

		try {
			_ensureViewletWrapped();
		} catch ( any e ) {
			variables.viewletWrapped = false;
		}
	}

	public void function preProcess( event ) {
		_tracker().begin( arguments.event );
		_ensureViewletWrapped();
		_ensureSelectDataWrapped();
		_ensureRenderDataWrapped( arguments.event );
		luceeDebuggingService.get().applyRequestMonitoringOutput();
	}

	public void function preEvent( event, interceptData ) {
		var eventName = arguments.interceptData.processedEvent ?: "";

		if ( !Len( eventName ) ) {
			try {
				eventName = arguments.event.getCurrentEvent();
			} catch ( any e ) {
				eventName = "";
			}
		}

		if ( _isScheduledTask( arguments.event ) ) {
			_tracker().beginTask( kind="task", label="", eventName=eventName );
		} else if ( !_isBackgroundWork( arguments.event ) ) {
			_tracker().noteEvent( eventName );
			_tracker().noteUrl( _currentUrl( arguments.event ) );
		}

		_beginFrame(
			  interceptData = arguments.interceptData
			, kind          = "event"
			, name          = eventName
		);
	}

	public void function preViewRender( event, interceptData ) {
		_beginFrame(
			  interceptData = arguments.interceptData
			, kind          = "view"
			, name          = _qualifiedName( arguments.interceptData.view ?: "", arguments.interceptData.module ?: "" )
		);
	}

	public void function postViewRender( event, interceptData ) {
		_endFrame( arguments.interceptData );
	}

	public void function preLayoutRender( event, interceptData ) {
		_beginFrame(
			  interceptData = arguments.interceptData
			, kind          = "layout"
			, name          = _qualifiedName( _stripCfm( arguments.interceptData.layout ?: "" ), arguments.interceptData.module ?: "" )
		);
	}

	public void function postLayoutRender( event, interceptData ) {
		_endFrame( arguments.interceptData );
	}

	public void function postInitializePresideSiteteePage( event, interceptData ) {
		var pageType  = "";
		var pageTitle = "";

		try {
			pageType  = arguments.event.getPageProperty( propertyName="page_type", defaultValue="" );
			pageTitle = arguments.event.getPageProperty( propertyName="title", defaultValue="" );
		} catch ( any e ) {
			return;
		}

		_tracker().notePage( pageType=pageType, pageTitle=pageTitle );
	}

	public void function postEvent( event, interceptData ) {
		_endFrame( arguments.interceptData );
		_tracker().endTaskEvent( arguments.interceptData.processedEvent ?: "" );
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
			var sampler = _sampler();

			sampler.closeOpenFrames();

			var type         = "http";
			var pageUrl      = event.getCurrentUrl();
			var adminUser    = event.getAdminUserId();
			var webUser      = _safeWebUserId();
			var allocations  = sampler.getRows();

			if ( Len( event.getValue( name="_runningAdhocTaskId", defaultValue="", private=true ) ) ) {
				type    = "adhoctask";
				pageUrl = event.getCurrentEvent();
			} else if ( event.isBackgroundThread() ) {
				type    = "task";
				pageUrl = event.getCurrentEvent();
			}

			luceeDebuggingService.get().log(
				  pageUrl     = pageUrl
				, adminuser   = adminUser
				, webuser     = webUser
				, type        = type
				, allocations = allocations
			);
		} catch ( any e ) {
			writeLog(
				  type = "error"
				, file = "performanceanalyser"
				, text = "Failed to persist debug log: #e.message# | #e.detail# | #e.stacktrace#"
			);
		} finally {
			_tracker().end();
		}
	}

	private boolean function _isScheduledTask( required any event ) {
		try {
			return arguments.event.isBackgroundThread() && !Len( arguments.event.getValue( name="_runningAdhocTaskId", defaultValue="", private=true ) );
		} catch ( any e ) {
			return false;
		}
	}

	private boolean function _isBackgroundWork( required any event ) {
		try {
			return arguments.event.isBackgroundThread() || Len( arguments.event.getValue( name="_runningAdhocTaskId", defaultValue="", private=true ) );
		} catch ( any e ) {
			return false;
		}
	}

	private any function _tracker() {
		if ( !StructKeyExists( variables, "tracker" ) ) {
			variables.tracker = activeRequestTracker.get();
		}

		return variables.tracker;
	}

	private string function _currentUrl( required any event ) {
		try {
			return arguments.event.getCurrentUrl();
		} catch ( any e ) {
			return "";
		}
	}

	private any function _sampler() {
		if ( !StructKeyExists( variables, "sampler" ) ) {
			variables.sampler = allocationSampler.get();
		}

		return variables.sampler;
	}

	private void function _beginFrame( required struct interceptData, required string kind, required string name ) {
		arguments.interceptData[ variables.frameKey ] = _sampler().start(
			  kind = arguments.kind
			, name = arguments.name
		);
	}

	private void function _endFrame( required struct interceptData ) {
		var frameId = arguments.interceptData[ variables.frameKey ] ?: "";

		if ( Len( frameId ) ) {
			_sampler().stop( frameId );
			StructDelete( arguments.interceptData, variables.frameKey );
		}
	}

	private string function _qualifiedName( required string name, string module="" ) {
		var frameName = _stripCfm( arguments.name );

		if ( !Len( frameName ) ) {
			return "";
		}
		if ( Len( arguments.module ?: "" ) ) {
			return arguments.module & ":" & frameName;
		}

		return frameName;
	}

	private string function _stripCfm( required string name ) {
		if ( Len( arguments.name ) > 4 && LCase( Right( arguments.name, 4 ) ) == ".cfm" ) {
			return Left( arguments.name, Len( arguments.name ) - 4 );
		}

		return arguments.name;
	}

	private void function _ensureViewletWrapped() {
		if ( variables.viewletWrapped ) {
			return;
		}

		var controller = variables.controller;

		lock name="perfAnalyserViewletWrap" type="exclusive" timeout="5" {
			if ( variables.viewletWrapped || StructKeyExists( controller, "_perfAnalyserViewletWrapped" ) ) {
				variables.viewletWrapped = true;
				return;
			}

			var sampler = _sampler();

			controller.originalRenderViewlet = controller.renderViewlet;
			StructDelete( controller, "renderViewlet" );

			controller.renderViewlet = function() {
				var prepostExempt = StructKeyExists( arguments, "prepostExempt" ) ? arguments.prepostExempt : true;

				if ( !sampler.isActive() || !prepostExempt ) {
					return controller.originalRenderViewlet( argumentCollection=arguments );
				}

				var eventName = arguments.event ?: ( arguments[ 1 ] ?: "" );
				var frameId   = sampler.start( kind="viewlet", name=eventName );

				try {
					return controller.originalRenderViewlet( argumentCollection=arguments );
				} finally {
					sampler.stop( frameId );
				}
			};

			controller._perfAnalyserViewletWrapped = true;
			variables.viewletWrapped               = true;
		}
	}

	private void function _ensureSelectDataWrapped() {
		if ( variables.selectWrapped ) {
			return;
		}

		var poService = presideObjectService.get();

		lock name="perfAnalyserSelectDataWrap" type="exclusive" timeout="5" {
			if ( variables.selectWrapped || StructKeyExists( poService, "_perfAnalyserSelectDataWrapped" ) ) {
				variables.selectWrapped = true;
				return;
			}

			var sampler = _sampler();

			poService.originalSelectData = poService.selectData;
			StructDelete( poService, "selectData" );

			poService.selectData = function() {
				var active = false;

				if ( !StructKeyExists( request, "_perfAnalyserInSelectWrap" ) ) {
					request._perfAnalyserInSelectWrap = true;
					try {
						active = sampler.isActive();
					} finally {
						StructDelete( request, "_perfAnalyserInSelectWrap" );
					}
				}

				if ( !active ) {
					return poService.originalSelectData( argumentCollection=arguments );
				}

				var objectName = arguments.objectName ?: ( arguments[ 1 ] ?: "" );
				var frameId    = sampler.start( kind="select", name=objectName );

				try {
					return poService.originalSelectData( argumentCollection=arguments );
				} finally {
					sampler.stop( frameId );
				}
			};

			poService._perfAnalyserSelectDataWrapped = true;
			variables.selectWrapped                  = true;
		}
	}

	private void function _ensureRenderDataWrapped( required any event ) {
		if ( StructKeyExists( arguments.event, "_perfAnalyserRenderDataWrapped" ) ) {
			return;
		}

		var sampler = _sampler();
		var ctx     = arguments.event;

		ctx.originalRenderData = ctx.renderData;
		StructDelete( ctx, "renderData" );

		ctx.renderData = function() {
			if ( !sampler.isActive() ) {
				return ctx.originalRenderData( argumentCollection=arguments );
			}

			var renderType = LCase( arguments.type ?: ( arguments[ 1 ] ?: "html" ) );
			var frameId    = sampler.start( kind="renderdata", name=renderType );

			try {
				return ctx.originalRenderData( argumentCollection=arguments );
			} finally {
				sampler.stop( frameId );
			}
		};

		ctx._perfAnalyserRenderDataWrapped = true;
	}

	private string function _safeWebUserId() {
		try {
			return getLoggedInUserId();
		} catch ( any e ) {
			return "";
		}
	}
}
