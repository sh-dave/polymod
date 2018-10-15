package polymod.backends.kha;

using StringTools;

class AssetIdTools {
    public static function sanitizeUrl( id: String )
        return id
            .replace('.', '_')
            .replace('-', '_')
            .replace('/', '_')
            .replace('\\', '_');

    public static function sanitizeImageUrl( id: String )
        return sanitizeUrl(id)
            .replace('_png', '')
            .replace('_jpg', '');
}