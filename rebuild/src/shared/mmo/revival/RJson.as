package mmo.revival
{
   /**
    * REVIVAL. JSON for the revival's own files (the 沙盒's 关卡): the 2013
    * client is built for Flash Player 10.1, which has no JSON class. Objects,
    * arrays, strings, numbers, true, false and null; decode throws an Error on
    * text that is not JSON.
    */
   public class RJson
   {
      public static function encode(v:*):String
      {
         if (v === null || v === undefined) return "null";
         if (v is Boolean) return v ? "true" : "false";
         if (v is Number) return isFinite(v) ? String(v) : "null";
         if (v is String) return quote(v);
         var parts:Array = [];
         if (v is Array)
         {
            for each (var item:* in v) parts.push(encode(item));
            return "[" + parts.join(",") + "]";
         }
         var keys:Array = [];
         for (var k:String in v) keys.push(k);
         keys.sort();
         for each (var key:String in keys) parts.push(quote(key) + ":" + encode(v[key]));
         return "{" + parts.join(",") + "}";
      }

      private static function quote(s:String):String
      {
         var out:String = "\"";
         for (var i:int = 0; i < s.length; i++)
         {
            var c:String = s.charAt(i);
            var n:int = s.charCodeAt(i);
            if (c == "\"" || c == "\\") out += "\\" + c;
            else if (c == "\n") out += "\\n";
            else if (c == "\r") out += "\\r";
            else if (c == "\t") out += "\\t";
            else if (n < 0x20) out += "\\u" + ("000" + n.toString(16)).substr(-4);
            else out += c;
         }
         return out + "\"";
      }

      private var s:String;
      private var i:int;

      public static function decode(text:String):*
      {
         var p:RJson = new RJson();
         p.s = text;
         p.i = 0;
         var v:* = p.value();
         p.space();
         if (p.i < p.s.length) throw new Error("JSON: unexpected text at " + p.i);
         return v;
      }

      private function space():void
      {
         while (i < s.length && " \t\r\n﻿".indexOf(s.charAt(i)) >= 0) i++;
      }

      private function value():*
      {
         space();
         if (i >= s.length) throw new Error("JSON: unexpected end");
         var c:String = s.charAt(i);
         if (c == "{") return object();
         if (c == "[") return array();
         if (c == "\"") return string();
         if (s.substr(i, 4) == "true") { i += 4; return true; }
         if (s.substr(i, 5) == "false") { i += 5; return false; }
         if (s.substr(i, 4) == "null") { i += 4; return null; }
         return number();
      }

      private function object():Object
      {
         var o:Object = {};
         i++;
         space();
         if (s.charAt(i) == "}") { i++; return o; }
         while (true)
         {
            space();
            if (s.charAt(i) != "\"") throw new Error("JSON: a key expected at " + i);
            var k:String = string();
            space();
            if (s.charAt(i) != ":") throw new Error("JSON: ':' expected at " + i);
            i++;
            o[k] = value();
            space();
            var c:String = s.charAt(i++);
            if (c == "}") return o;
            if (c != ",") throw new Error("JSON: ',' or '}' expected at " + (i - 1));
         }
         return o;
      }

      private function array():Array
      {
         var a:Array = [];
         i++;
         space();
         if (s.charAt(i) == "]") { i++; return a; }
         while (true)
         {
            a.push(value());
            space();
            var c:String = s.charAt(i++);
            if (c == "]") return a;
            if (c != ",") throw new Error("JSON: ',' or ']' expected at " + (i - 1));
         }
         return a;
      }

      private function string():String
      {
         var out:String = "";
         i++;
         while (i < s.length)
         {
            var c:String = s.charAt(i++);
            if (c == "\"") return out;
            if (c != "\\")
            {
               out += c;
               continue;
            }
            var e:String = s.charAt(i++);
            switch (e)
            {
               case "n": out += "\n"; break;
               case "r": out += "\r"; break;
               case "t": out += "\t"; break;
               case "b": out += "\b"; break;
               case "f": out += "\f"; break;
               case "u": out += String.fromCharCode(parseInt(s.substr(i, 4), 16)); i += 4; break;
               default: out += e;
            }
         }
         throw new Error("JSON: unterminated string");
      }

      private function number():Number
      {
         var m:Array = s.substr(i).match(/^-?\d+(\.\d+)?([eE][+-]?\d+)?/);
         if (m == null) throw new Error("JSON: unexpected '" + s.charAt(i) + "' at " + i);
         i += String(m[0]).length;
         return Number(m[0]);
      }
   }
}
