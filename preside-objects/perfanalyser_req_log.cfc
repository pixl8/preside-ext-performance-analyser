/**
 * @versioned      false
 * @nolabel        true
 * @nodatemodified true
 * @tableprefix    ""
 * @datamanagerEnabled true
 * @datamanagerGridFields type,url,total_time,query_time,query_count,datecreated
 * @datamanagerDefaultSortOrder datecreated desc
 */
component {
	property name="id"         type="numeric" dbtype="bigint" generator="increment";
	property name="type"       type="string"  dbtype="varchar" required=true maxlength=10 indexes="reqtype" enum="luceeDebugRequestTypes";
	property name="url"        type="string"  dbtype="text"    required=true;
	property name="url_hash"   type="string"  dbtype="char"    required=true maxlength=35 indexes="urlhash";
	property name="total_time" type="numeric" dbtype="int"     required=true              indexes="totaltime";
	property name="query_time" type="numeric" dbtype="int"     required=true              indexes="querytime";

	property name="web_user"   relationship="many-to-one" relatedto="website_user" feature="websiteusers";
	property name="admin_user" relationship="many-to-one" relatedto="security_user";

	property name="queries" relationship="one-to-many" relatedto="perfanalyser_req_log_query" relationshipKey="req";
	property name="query_count" type="numeric" formula="agg:count{ queries.req }";
}