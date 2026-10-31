package mmo.fbteam.fbsiwude.sceneplayer.scene10
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class FBSiwude10_2Fight4 extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const frameName:Array = ["second1","second2","second3"];
      
      private var petIds:Array = [1,2,3,4];
      
      private var petViews:Array = [];
      
      private var fightIndex:int = 0;
      
      private var ipf:IPetFight = null;
      
      private var fightedCount:int = 0;
      
      private var kills:Array = [false,false,false,false];
      
      public function FBSiwude10_2Fight4()
      {
         super();
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         var _loc3_:MovieClip = null;
         var _loc1_:DisplayObjectContainer = this.sceneInfo.scene.container;
         var _loc2_:int = 0;
         while(_loc2_ < 4)
         {
            _loc3_ = _loc1_.getChildByName("btnPet_" + (_loc2_ + 1)) as MovieClip;
            this.petViews.push(_loc3_);
            _loc2_++;
         }
      }
      
      private function initFuns() : void
      {
         var _loc1_:MovieClip = null;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         for each(_loc1_ in this.petViews)
         {
            _loc1_.addEventListener(MouseEvent.CLICK,this.onClickAndFight);
         }
      }
      
      private function onClickAndFight(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         var _loc3_:int = this.petViews.indexOf(_loc2_);
         this.ipf.fightInCopy(this.petIds[_loc3_]);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         this.isClicking = false;
         if(param1.isWin)
         {
            ++this.fightedCount;
            _loc2_ = int(param1.id);
            _loc3_ = this.petIds.indexOf(_loc2_);
            this.killPet(_loc3_);
            if(!this.showAlivePetTalk())
            {
               this.movieFinish(-1,this.type);
            }
         }
      }
      
      private function killPet(param1:int) : void
      {
         var _loc2_:MovieClip = this.petViews[param1] as MovieClip;
         if(null != _loc2_)
         {
            this.kills[param1] = true;
            _loc2_.gotoAndStop("secondkill");
            _loc2_.removeEventListener(MouseEvent.CLICK,this.onClickAndFight);
            this.petViews[param1] = null;
         }
      }
      
      private function showAlivePetTalk() : Boolean
      {
         var _loc1_:int = 0;
         var _loc2_:MovieClip = null;
         if(this.fightedCount <= 3)
         {
            _loc1_ = 0;
            while(_loc1_ < 4)
            {
               if(!this.kills[_loc1_])
               {
                  _loc2_ = this.petViews[_loc1_] as MovieClip;
                  _loc2_.gotoAndStop(this.frameName[this.fightedCount - 1]);
               }
               _loc1_++;
            }
            return true;
         }
         return false;
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         var _loc1_:int = 0;
         while(_loc1_ < 4)
         {
            this.killPet(_loc1_);
            _loc1_++;
         }
      }
   }
}

