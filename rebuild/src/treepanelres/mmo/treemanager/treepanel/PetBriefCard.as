package mmo.treemanager.treepanel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.revival.RArt;

   /** REBUILT (the 2012 code on its art, symbol 22): a 亚比 of the bag, to choose as the 守护亚比. */
   public class PetBriefCard extends Sprite
   {
      public var ps:MovieClip;
      public var followMC:MovieClip;
      public var rideMC:MovieClip;
      public var txtHp:TextField;
      public var txtName:TextField;
      public var hpmc:MovieClip;
      public var iconcontainer:MovieClip;
      public var txt:TextField;
      public var txtLevel:TextField;

      public var petInfo:PetBriefInfo;

      public function PetBriefCard(info:PetBriefInfo)
      {
         super();
         petInfo = info;
         buttonMode = useHandCursor = true;
         for each (var t:TextField in [txtName, txt, txtLevel, txtHp]) if (t != null) t.mouseEnabled = false;
         if (txtName != null) txtName.text = info.nickname || info.name;
         if (txtLevel != null) txtLevel.text = String(info.level);
         if (txtHp != null) txtHp.text = info.curHp + "/" + info.maxHp;
         if (hpmc != null) hpmc.gotoAndStop(Math.max(1, int(100 * info.curHp / Math.max(1, info.maxHp))));
         if (followMC != null) followMC.visible = false;
         if (rideMC != null) rideMC.visible = false;
         if (ps != null) ps.gotoAndStop(1);
         if (iconcontainer != null)
         {
            var pic:Sprite = new Sprite();
            pic.mouseEnabled = pic.mouseChildren = false;
            pic.x = iconcontainer.width / 2;
            pic.y = iconcontainer.height / 2;
            iconcontainer.addChild(pic);
            RArt.pet(pic, info.viewId, Math.max(30, Math.min(iconcontainer.width, iconcontainer.height)));
         }
      }

      public function setOnClick(on:Boolean):void
      {
         if (ps != null) ps.gotoAndStop(on ? 2 : 1);
      }
   }
}
