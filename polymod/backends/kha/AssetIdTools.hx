package polymod.backends.kha;

using StringTools;

class AssetIdTools {
    public static function sanitize( id: String )
        return id
            .replace('.', '_')
            .replace('-', '_')
            .replace('/', '_')
            .replace('\\', '_');

    public static function sanitizeImage( id: String )
        return sanitize(id)
            .replace('_png', '')
            .replace('_jpg', '');
}