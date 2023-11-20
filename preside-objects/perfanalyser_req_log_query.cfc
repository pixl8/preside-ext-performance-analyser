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

	property name="sql"         type="string" dbtype="text" require=true;
	property name="sql_hash"    type="string" dbtype="char" maxlength=35 require=true indexes="qryhash";
	property name="exec_time"   type="numeric" dbtype="int" require=true indexes="exectime";
	property name="recordcount" type="numeric" dbtype="int" require=true indexes="recordcount";
}