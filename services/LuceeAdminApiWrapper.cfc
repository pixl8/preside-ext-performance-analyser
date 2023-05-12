/**
 * @singleton true
 */
component {

	property name="luceeadminPassword" inject="coldbox:setting:performanceAnalyser.luceeAdminPassword";

// PUBLIC API METHODS

	public any function call( action, type="web" ) {
		var result      = "";
		var callAttribs = {
			  action         = arguments.action
			, type           = arguments.type
			, password       = luceeadminPassword
			, returnVariable = "result"
		};

		StructAppend( callAttribs, arguments, false );

		admin attributeCollection=callAttribs;

		if ( !IsNull( local.result ) ) {
			return result;
		}
	}

	public boolean function canConnect( type="web" ) {
		try {
			/**
			 * It would make sense to use action="connect" here.
			 * However, Lucee throws an error here when you have open api acces (no password)
			 * even though we *can* connect.
			*/
			call( action="getDebug", type=arguments.type );
		} catch( any e ) {
			return false;
		}

		return true;
	}
}