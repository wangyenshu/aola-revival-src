package mmo.revival
{
   import flash.utils.ByteArray;

   /**
    * REVIVAL. Base64 for the revival's own files (the pictures of a 沙盒 关卡
    * pack, data: URLs): Flash Player 10.1 has no decoder of its own.
    */
   public class RBase64
   {
      private static const CHARS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      private static var table:Array;

      /** The bytes of a base64 text (whitespace and anything else outside the alphabet skipped). */
      public static function decode(s:String):ByteArray
      {
         if (table == null)
         {
            table = [];
            for (var t:int = 0; t < 256; t++) table[t] = -1;
            for (var c:int = 0; c < CHARS.length; c++) table[CHARS.charCodeAt(c)] = c;
         }
         var out:ByteArray = new ByteArray();
         var acc:int = 0;
         var bits:int = 0;
         var n:int = s.length;
         for (var i:int = 0; i < n; i++)
         {
            var code:int = s.charCodeAt(i);
            if (code == 61) break; // "="
            var v:int = code < 256 ? int(table[code]) : -1;
            if (v < 0) continue;
            acc = (acc << 6) | v;
            bits += 6;
            if (bits >= 8)
            {
               bits -= 8;
               out.writeByte((acc >> bits) & 0xFF);
            }
         }
         out.position = 0;
         return out;
      }

      /** The bytes of a data: URL ("data:image/png;base64,…"); null when it is not one in base64. */
      public static function fromDataUrl(url:String):ByteArray
      {
         if (url == null || url.substr(0, 5) != "data:") return null;
         var comma:int = url.indexOf(",");
         if (comma < 0 || url.substring(0, comma).indexOf(";base64") < 0) return null;
         return decode(url.substr(comma + 1));
      }
   }
}
