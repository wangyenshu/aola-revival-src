package mmo.petfightnew
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;

   /**
    * REBUILT: the 属性等级 a fighting 亚比 has (its stages), shown while the mouse is over it. The
    * 2013 battle screen is lost; this is the later battle module's own panel on its art (character
    * 2837 of pet/petfightnew, mmo.petfightnew.common.panel.AttributeLevelPanel): a row for each
    * stage not 0, spAtt0 … spAtt7 from the top, each with mcDes (frame 1–8: 攻击 防御 特攻 特防
    * 速度 命中 闪避 暴击), mcState (1 up, 2 down) and in it mcNum (the level).
    */
   public dynamic class AttributeLevelPanel extends Sprite
   {
      private static const TOTAL:int = 8;

      /**
       * Made with the battle screen and kept on it, hidden: its clips build their first frames
       * before anything goes to a frame (stopped before that, they would draw nothing).
       */
      public function AttributeLevelPanel()
      {
         super();
         mouseEnabled = mouseChildren = false;
      }

      /** levels: the 8 stages (PetBriefInfo.bal). Whether any is shown. */
      public function setLevels(levels:Array):Boolean
      {
         var row:int = 0;
         for (var i:int = 0; i < TOTAL; i++)
         {
            var n:int = int(levels[i]);
            if (n == 0) continue;
            var sp:DisplayObjectContainer = getChildByName("spAtt" + row) as DisplayObjectContainer;
            if (sp == null) break;
            sp.visible = true;
            var des:MovieClip = sp.getChildByName("mcDes") as MovieClip;
            if (des) des.gotoAndStop(i + 1);
            var state:MovieClip = sp.getChildByName("mcState") as MovieClip;
            if (state)
            {
               state.gotoAndStop(n > 0 ? 1 : 2);
               var num:MovieClip = state.getChildByName("mcNum") as MovieClip;
               if (num) num.gotoAndStop(Math.min(num.totalFrames, Math.abs(n)));
            }
            row++;
         }
         for (var j:int = row; j < TOTAL; j++)
         {
            var rest:Sprite = getChildByName("spAtt" + j) as Sprite;
            if (rest) rest.visible = false;
         }
         return row > 0;
      }

   }
}
