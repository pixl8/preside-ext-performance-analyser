/**
 * @versioned      false
 * @nolabel        true
 * @nodatemodified true
 * @nodatecreated  true
 * @tableprefix    ""
 */
component {
	property name="id" type="numeric" dbtype="bigint" generator="increment";

	property name="req" relationship="many-to-one" relatedto="perfanalyser_req_log" required=true ondelete="cascade";

	property name="kind"            type="string"  dbtype="varchar" required=true maxlength="20"  indexes="kind";
	property name="name"            type="string"  dbtype="varchar" required=true maxlength="255" indexes="name";
	property name="call_count"      type="numeric" dbtype="int"     required=true                 indexes="callcount";
	property name="inclusive_bytes" type="numeric" dbtype="bigint"  required=true                 indexes="inclusivebytes";
	property name="exclusive_bytes" type="numeric" dbtype="bigint"  required=true                 indexes="exclusivebytes";
	property name="max_inclusive"   type="numeric" dbtype="bigint"  required=true;
	property name="max_exclusive"   type="numeric" dbtype="bigint"  required=true;

	property name="path_hash"   type="string" dbtype="varchar" required=false maxlength="32" default="";
	property name="parent_hash" type="string" dbtype="varchar" required=false maxlength="32" default="" indexes="parenthash";
}
