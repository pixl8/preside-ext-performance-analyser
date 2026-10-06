/**
 * @labelfield                   label
 * @datamanagerEnabled           true
 * @datamanagerGridFields        label,thread_count,datecreated
 * @datamanagerDefaultSortOrder  datecreated desc
 * @datamanagerAllowedOperations view,delete,batchdelete
 * @nodatemodified               true
 * @versioned                    false
 */
component {
	property name="label"        type="string"  dbtype="varchar"  maxlength=50 required=true;
	property name="thread_count" type="numeric" dbtype="int"                   required=true;
	property name="dump_text"    type="string"  dbtype="longtext"              required=false;

}
