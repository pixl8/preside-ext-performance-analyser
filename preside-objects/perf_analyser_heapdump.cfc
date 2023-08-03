/**
 * @labelfield                   filepath
 * @datamanagerEnabled           true
 * @datamanagerGridFields        filepath,size_in_bytes,datecreated
 * @datamanagerAllowedOperations view,delete,batchdelete
 * @nodatemodified               true
 * @versioned                    false
 */
component {
	property name="filepath" type="string" dbtype="varchar" maxlength=50 required=true indexes="filepath";
	property name="size_in_bytes" type="numeric" dbtype="bigint" required=true indexes="size" renderer="heapdumpFileSize";

}