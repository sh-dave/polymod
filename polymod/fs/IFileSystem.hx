package polymod.fs;

import haxe.io.Bytes;

interface IFileSystem {
    function exists( path: String ): Bool;
    function isDirectory( path: String ): Bool;
    function readDirectory( path: String ) : Array<String>;
    function getFileContent( path: String ): String;
    function getFileBytes( path: String ): Bytes;
    function readDirectoryRecursive( path: String ): Array<String>;
}
