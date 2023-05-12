component extends="lucee.admin.debug.Debug" {
	string function getLabel(){
		return "Empty";
	}
	string function getDescription(){
		return "Output nothing. Ensure that debug logging is purely in the background and does not effect front end pages.";
	}
	string function getid(){
		return "performance-analyser-empty";
	}

	void function output() output=true {echo("");};
}