<cfscript>
	settings   = prc.debugSettings ?: {};
	formName   = prc.formName      ?: "";
	postAction = prc.postAction    ?: "";
	cancelLink = prc.cancelLink    ?: "";
</cfscript>

<cfoutput>
	<p class="alert alert-warning">
		<i class="fa fa-fw fa-exclamation-triangle"></i>
		#translateResource( "performanceanalyser:edit.settings.warning" )#
	</p>

	<form class="form form-horizontal" method="post" action="#postAction#" id="edit-debug-settings-form">
		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = "edit-debug-settings-form"
			, savedData        = settings
			, validationResult = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelLink#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-fw fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button type="submit" class="btn btn-info" tabindex="#getNextTabIndex()#">
					<i class="fa fa-fw fa-save bigger-110"></i>

					#translateResource( "cms:datamanager.savechanges.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>

