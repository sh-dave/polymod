package polymod.backends.kha;

import haxe.io.Bytes;
import polymod.util.Util;

class ElectronFileSystem implements polymod.fs.IFileSystem {
    var fs: Dynamic = untyped require('fs');
    var cwd = untyped require('electron').remote.app.getAppPath();

    public function new() {
    }

    // function exists( path: String ): Bool;
    // function isDirectory( path: String ): Bool;
    // function readDirectory( path: String ) : Array<String>;
    // function getFileContent( path: String ): String;
    // function getFileBytes( path: String ): Bytes;
    // function readDirectoryRecursive( path: String ): Array<String>;

    public function exists( path: String ) : Bool
        return fs.existsSync('$cwd/$path');

    public function isDirectory( path: String ) : Bool {
        var p = '$cwd/$path';
        return fs.existsSync(p) && fs.lstatSync(p).isDirectory();
    }

    public function readDirectory( path: String ) : Array<String>
        return fs.readdirSync('$cwd/$path');

    public function readDirectoryRecursive( path: String ) : Array<String> {
		var all = _readDirectoryRecursive(path);

        for (i in 0...all.length) {
			var f = all[i];
			var stri = Util.uIndexOf(f, '$path/');

			if (stri == 0) {
				f = Util.uSubstr(f, Util.uLength('$path/'), Util.uLength(f));
				all[i] = f;
			}
		}
		return all;
    }

    public function getFileBytes( path: String )
        return Bytes.ofData(fs.readFileSync('$cwd/$path'));

    public function getFileContent( path: String ) : String
        return fs.readFileSync('$cwd/$path', { encoding: 'utf8' });

	function _readDirectoryRecursive( path: String ) : Array<String> {
		if (exists(path) && isDirectory(path)) {
			var all = readDirectory(path);

            if (all == null) {
                return [];
            }

			var results = [];

            for (thing in all) {
				if (thing == null) {
                    continue;
                }

				var pathToThing = path + Util.sl() + thing;

                if (isDirectory(pathToThing)) {
					var subs = _readDirectoryRecursive(pathToThing);

                    if (subs != null) {
						results = results.concat(subs);
					}
				} else {
					results.push(pathToThing);
				}
			}

			return results;
		}

		return [];
	}
}
