package mmo.pet.petcommon
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   
   public class PetSimpleView extends Sprite
   {
      
      private var kuangMC:MovieClip;
      
      private var petSkillMesService:IPetSkillMesService;
      
      public var kuang:MovieClip;
      
      private var _o:Object;
      
      private var eggIcon:Sprite;
      
      public function PetSimpleView(param1:Object)
      {
         super();
         this._o = param1;
         this.kuangMC = this.kuang;
         this.kuangMC.visible = false;
         this.mouseChildren = false;
         this.petSkillMesService = ServiceContainer.getService("PetSkillMesService") as IPetSkillMesService;
         trace("o.ri:" + param1.ri);
         var _loc2_:int = int(param1.ri);
         var _loc3_:Object = this.petSkillMesService.getPetMes(_loc2_);
         trace("mesObj.pname:" + _loc3_.pname);
         TipsManager.getInstance().addTips(this as InteractiveObject,_loc3_.pname,100);
         var _loc4_:Object = this.petSkillMesService.getPetMes(_loc2_);
         var _loc5_:int = int(_loc4_.type);
         this.eggIcon = this.petSkillMesService.getPetEggIconByRaceId(_loc2_);
         DisplayUtil.scaleDisplay(this.eggIcon,this.width * 0.8,this.height * 0.8);
         DisplayUtil.middleDisplay(this.eggIcon,this.width,this.height);
         this.addChild(this.eggIcon);
      }
      
      public function setkuang(param1:Boolean) : void
      {
         this.kuangMC.visible = param1;
      }
      
      public function get o() : Object
      {
         return this._o;
      }
      
      public function dispose() : void
      {
         TipsManager.getInstance().removeTips(this);
         this.parent.removeChild(this);
      }
   }
}

