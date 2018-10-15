package polymod.backends;

#if kha
import haxe.io.Bytes;
import polymod.fs.IFileSystem;
import polymod.backends.kha.AssetIdTools;

using polymod.util.Util;

private enum KhaAsset {
    Blob( id: String );
    Font( id: String );
    Image( id: String );
    Sound( id: String );
    Video( id: String );
}

class KhaBackend implements IBackend {
    public var polymodLibrary: PolymodAssetLibrary;
    public var fileSystem(default, null): IFileSystem;

    var defaultBlobs: Map<String, Dynamic> = new Map();
    var defaultImages: Map<String, Dynamic> = new Map();
    var defaultSounds: Map<String, Dynamic> = new Map();
    var defaultVideos: Map<String, Dynamic> = new Map();
    var defaultFonts: Map<String, Dynamic> = new Map();

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
            var assetId = AssetIdTools.sanitizeUrl(file);

            switch assetType {
                case AUDIO_GENERIC:
                    defaultBlobs.set(file, kha.Assets.blobs.get(assetId));
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case AUDIO_MUSIC:
                    defaultSounds.set(file, kha.Assets.sounds.get(assetId));
                    moddedSounds.set(file, polymodLibrary.file(file));
                case AUDIO_SOUND:
                    defaultSounds.set(file, kha.Assets.sounds.get(assetId));
                    moddedSounds.set(file, polymodLibrary.file(file));
                case BYTES:
                    defaultBlobs.set(file, kha.Assets.blobs.get(assetId));
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case FONT:
                    defaultFonts.set(file, kha.Assets.fonts.get(assetId));
                    moddedFonts.set(file, polymodLibrary.file(file));
                case IMAGE:
                    defaultImages.set(file, kha.Assets.images.get(assetId));
                    moddedImages.set(file, polymodLibrary.file(file));
                case MANIFEST:
                    defaultBlobs.set(file, kha.Assets.blobs.get(assetId));
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case TEMPLATE:
                    defaultBlobs.set(file, kha.Assets.blobs.get(assetId));
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case TEXT:
                    defaultBlobs.set(file, kha.Assets.blobs.get(assetId));
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case UNKNOWN:
                    defaultBlobs.set(file, kha.Assets.blobs.get(assetId));
                    moddedBlobs.set(file, polymodLibrary.file(file));
                case VIDEO:
                    defaultVideos.set(file, kha.Assets.videos.get(assetId));
                    moddedVideos.set(file, polymodLibrary.file(file));
            }
        }

        function inject( todo: Map<String, String>, list: Dynamic, sfn: String -> String ) {
            for (key in todo.keys()) {
                var id = sfn(key);
                var desc = Reflect.field(list, '${id}Description');

                if (desc != null) {
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
        // for(key in Assets.info.keys())
        // {
        //     var assetInfo = Assets.info.get(key);
        //     if(assetInfo != null && assetInfo.type == AssetType.IMAGE)
        //     {
        //         if(assetInfo.type == AssetType.IMAGE)
        //         {
        //             Assets.cache.removeBitmapData(assetInfo.path);
        //         }
        //         assetInfo.cache = null;
        //     }
        // }
    }

    public function destroy()
    {
        restoreDefaultAssets();
        polymodLibrary = null;
        // modAssets = null;
        // defaultAssets = null;
    }

    function restoreDefaultAssets() {
        // if (modAssets == null) {
        //     return;
        // }

        // for (key in modAssets.keys()) {
        //     var modAsset = modAssets.get(key);

        //     if (modAsset != null) {
        //         // nme.Assets.info.remove(key);

        //         // TODO (DK) for all types
        //         Reflect.deleteField(kha.Assets.blobs, key);
        //     }

        //     var defaultAsset = defaultAssets.get(key);

        //     if (defaultAsset != null) {
        //         // nme.Assets.info.set(key, defaultAsset);

        //         // TODO (DK) for all types
        //         Reflect.setField(kha.Assets.blobs, '', defaultAsset); // TODO (DK) name
        //     }
        // }
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
