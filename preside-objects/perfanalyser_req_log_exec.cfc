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

	property name="template_path" type="string"  dbtype="varchar" required=true  maxlength="255" indexes="template";
	property name="method_name"   type="string"  dbtype="varchar" required=true maxlength="255" indexes="method";
	property name="call_count"    type="numeric" dbtype="int"     required=true                   indexes="callcount";
	property name="min_time"      type="numeric" dbtype="int"     required=true                   indexes="mintime";
	property name="max_time"      type="numeric" dbtype="int"     required=true                   indexes="maxtime";
	property name="mean_time"     type="numeric" dbtype="int"     required=true                   indexes="meantime";
	property name="total_time"    type="numeric" dbtype="int"     required=true                   indexes="totaltime";
	property name="load"          type="numeric" dbtype="int"     required=true                   indexes="load";
}