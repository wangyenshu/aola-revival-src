package mmo.common.datastructure
{
   /**
    * LATER: the later common library's number kept scrambled in memory (against memory editors),
    * which the later copies of 飞天独角兽 (game/flyingunicorn: its score) and 毛毛飞天记
    * (game/penguin: its metres) keep their counts in. The 2013 library lacks it and those games
    * stopped as they were made; it is in play.swf so they find it. Written again: the value
    * kept with a random key.
    */
   public class ConfuseNumber
   {
      private var key:Number;
      private var kept:Number;

      public function ConfuseNumber(value:Number = 0)
      {
         super();
         setValue(value);
      }

      public function getValue():Number
      {
         return kept - key;
      }

      public function setValue(value:Number):void
      {
         key = Math.floor(Math.random() * 100000) + 1;
         kept = value + key;
      }

      public function add(value:Number):void
      {
         setValue(getValue() + value);
      }

      public function toString():String
      {
         return String(getValue());
      }
   }
}
