package polymod.backends;

#if kha
import haxe.io.Bytes;
import polymod.fs.IFileSystem;
import polymod.backends.kha.AssetIdTools;

using polymod.util.Util;

class KhaBackend implements IBackend {
    public var polymodLibrary: PolymodAssetLibrary;
    public var fileSystem(default, null): IFileSystem;

    var backupCallbacks: Array<Void -> Void> = [];
    var moddedBlobs: Map<String, String> = new Map();
    var moddedImages: Map<String, String> = new Map();
    var moddedSounds: Map<String, String> = new Map();
    var moddedVideos: Map<String, String> = new Map();
    var moddedFonts: Map<String, String> = new Map();

    public function new( fileSystem: IFileSystem ) {
        this.fileSystem = fileSystem != null
            ? fileSystem
            : #if kha_debug_html5
                new polymod.backends.kha.ElectronFileSystem();
            #elseif kha_kore
                new polymod.fs.SysFileSystem();
            #else
                new polymod.fs.StubFileSystem();
            #end
    }

    public function init() {
        restoreDefaultAssets();

        var list = polymodLibrary.listModFiles();

        for (file in list) {
            var assetType = polymodLibrary.getType(file);

            switch assetType {
                case AUDIO_GENERIC:
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case AUDIO_MUSIC:
                    moddedSounds.set(file, polymodLibrary.file(file));
                case AUDIO_SOUND:
                    moddedSounds.set(file, polymodLibrary.file(file));
                case BYTES:
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case FONT:
                    moddedFonts.set(file, polymodLibrary.file(file));
                case IMAGE:
                    moddedImages.set(file, polymodLibrary.file(file));
                case MANIFEST:
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case TEMPLATE:
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case TEXT:
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case UNKNOWN:
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case VIDEO:
                    moddedVideos.set(file, polymodLibrary.file(file));
            }
        }

        function inject( todo: Map<String, String>, list: Dynamic, sfn: String -> String ) {
            for (key in todo.keys()) {
                var id = sfn(key);
                var desc = Reflect.field(list, '${id}Description');

                if (desc != null) {
                    var old = Reflect.field(desc, 'files');

                    backupCallbacks.push(function() {
                        Reflect.setField(desc, 'files', old);
                    });

                    Reflect.setField(desc, 'files', [todo.get(key)]);
                }
            }
        }

        var blobs = kha.Assets.blobs;
        trace(blobs);

        inject(moddedBlobs, kha.Assets.blobs, AssetIdTools.sanitizeUrl);
        inject(moddedImages, kha.Assets.images, AssetIdTools.sanitizeImageUrl);
        inject(moddedFonts, kha.Assets.fonts, AssetIdTools.sanitizeUrl);
        inject(moddedSounds, kha.Assets.sounds, AssetIdTools.sanitizeUrl);
        inject(moddedVideos, kha.Assets.videos, AssetIdTools.sanitizeUrl);

        // merge and append text files
        // for (key in nme.Assets.info.keys()) {
        //     var info = nme.Assets.info.get(key);

        //     if (info.type == TEXT) {
        //         if (info.isResource) {
        //             var origText = PolymodAssets.getText(key);
        //             var newText = polymodLibrary.mergeAndAppendText(key, origText);

        //             if(origText != newText) {
        //                 var byteArray = nme.utils.ByteArray.fromBytes(Bytes.ofString(newText));
        //                 info.setCache(byteArray, true);
        //                 info.isResource = false;
        //             }
        //         } else {
        //             nme.Assets.byteFactory.set( info.path, function(){
        //                 var bytes = PolymodFileSystem.getFileBytes(key);
        //                 var origText = Std.string(bytes);
        //                 var newText = polymodLibrary.mergeAndAppendText(key, origText);

        //                 if (origText != newText) {
        //                     return nme.utils.ByteArray.fromBytes(Bytes.ofString(newText));
        //                 }

        //                 return nme.utils.ByteArray.fromBytes(Bytes.ofString(origText));
        //             });
        //         }
        //     }
        // }
    }

    public function exists( id: String )
        return kha.Assets.blobs.get(AssetIdTools.sanitizeUrl(id)) != null;

    public function getBytes( id: String ) : Bytes
        return kha.Assets.blobs.get(AssetIdTools.sanitizeUrl(id)).toBytes();

    public function getText(id:String)
        return getBytes(id).toString();

    public function clearCache() {
    }

    public function destroy() {
        restoreDefaultAssets();
        polymodLibrary = null;
    }

    function restoreDefaultAssets() {
        for (cb in backupCallbacks) {
            cb();
        }

        backupCallbacks = [];
        moddedBlobs = new Map();
        moddedImages = new Map();
        moddedSounds = new Map();
        moddedVideos = new Map();
        moddedFonts = new Map();
    }

    public function stripAssetsPrefix( id: String ) : String {
        if (Util.uIndexOf(id, "assets/") == 0 || Util.uIndexOf(id, "Assets/") == 0) {
            id = Util.uSubstring(id, 7);
        }

        return id;
    }
}

#else
class KhaBackend extends StubBackend {
    public function new( fileSystem: IFileSystem ) {
        super();
        Polymod.error(FAILED_CREATE_BACKEND,"KhaBackend requires the Kha library, did you forget to install it?");
    }
}
#end
