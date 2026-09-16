/**
 * @presideService true
 * @singleton      true
 */
component {

	property name="storageProvider" inject="performanceAnalyserStorageProvider";
	property name="heapdumpDao"     inject="presidecms:object:perf_analyser_heapdump";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function getHeapDump() {
		var mf          = CreateObject( "java", "java.lang.management.ManagementFactory" );
		var mxBeanClass = CreateObject( "java", "com.sun.management.HotSpotDiagnosticMXBean" ).getClass();
		var mxBean      = mf.newPlatformMXBeanProxy( mf.getPlatformMBeanServer(), "com.sun.management:type=HotSpotDiagnostic", mxBeanClass );
		var tmpFile     = getTempFile( getTempDirectory(), "heapdump" ) & ".hprof";
		var storedPath  = "/heapdumps/#DateTimeFormat( Now(), 'yyyy-mm-dd_hhnnss' )#.hprof"

		mxBean.dumpHeap( tmpFile, true );

		var tmpFileInfo = GetFileInfo( tmpFile );

		storageProvider.putObjectFromLocalPath(
			  localPath = tmpFile
			, path      = storedPath
			, private   = true
		);

		var dumpId = heapdumpDao.insertData( { filepath=storedPath, size_in_bytes=tmpFileInfo.size } );

		return getHeapDumpUrl( dumpId );
	}

	public string function getHeapDumpUrl( required string dumpId ) {
		var storedPath = heapdumpDao.selectData( id=dumpId, selectFields=[ "filepath" ] ).filepath;

		if ( !Len( storedPath ) ) {
			return "";
		}

		if ( StructKeyExists( storageProvider, "getTemporaryPrivateObjectUrl" ) ) {
			return storageProvider.getTemporaryPrivateObjectUrl( storedPath );
		}

		return $getRequestContext().buildLink(
			  fileStoragePath     = storedPath
			, fileStorageProvider = "performanceAnalyserStorageProvider"
			, fileStoragePrivate  = true
		);
	}

	public void function deleteDumpFile( required string path ) {
		try {
			storageProvider.deleteObject( path=arguments.path, private=true );
		} catch( any e ) {
			$raiseError( e );
		}
	}

}