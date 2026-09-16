( function( $ ){

	var $debugEnabledRadio = $( "#debug" )
	  , $showLogsRadio = $( "#showlogs" )
	  , $featuresField = $( "[name=features]" ).first().closest( ".form-group" )
	  , $ipaddressesField = $( "#ipaddresses" ).closest( ".form-group" )
	  , $displayFieldset = $( "#fieldset-display" )
	  , toggleFeatures, togglePageDisplayFeatures;

	if ( $debugEnabledRadio.length ) {
		toggleEnabledFeatures = function(){
			if ( $debugEnabledRadio.is( ":checked" ) ) {
				$featuresField.show();
				$displayFieldset.show();
				togglePageDisplayFeatures();
			} else {
				$featuresField.hide();
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