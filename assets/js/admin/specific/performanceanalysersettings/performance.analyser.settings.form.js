( function( $ ){

	var $debugEnabledRadio = $( "#debug" )
	  , $showLogsRadio = $( "#showlogs" )
	  , $featuresField = $( "[name=features]" ).first().closest( ".form-group" )
	  , $trackAllocationField = $( "#trackallocation" ).closest( ".form-group" )
	  , $ipaddressesField = $( "#ipaddresses" ).closest( ".form-group" )
	  , $displayFieldset = $( "#fieldset-display" )
	  , toggleFeatures, togglePageDisplayFeatures;

	if ( $debugEnabledRadio.length ) {
		toggleEnabledFeatures = function(){
			if ( $debugEnabledRadio.is( ":checked" ) ) {
				$featuresField.show();
				$trackAllocationField.show();
				$displayFieldset.show();
				togglePageDisplayFeatures();
			} else {
				$featuresField.hide();
				$trackAllocationField.hide();
				$displayFieldset.hide();
			}
		};
		togglePageDisplayFeatures = function(){
			if ( $showLogsRadio.is( ":checked" ) ) {
				$ipaddressesField.show();
			} else {
				$ipaddressesField.hide();
			}
		};

		$debugEnabledRadio.on( "click", toggleEnabledFeatures );
		$showLogsRadio.on( "click", togglePageDisplayFeatures );

		toggleEnabledFeatures();
	}

} )( presideJQuery );