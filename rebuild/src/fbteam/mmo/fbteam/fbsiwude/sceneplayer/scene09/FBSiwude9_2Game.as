package mmo.fbteam.fbsiwude.sceneplayer.scene09
{
   import com.greensock.TweenMax;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class FBSiwude9_2Game extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const petIds:Array = [1,2];
      
      private var ants:Array = [];
      
      private var hands:Array = [];
      
      private var ipf:IPetFight = null;
      
      private var fightedCount:int = 0;
      
      public function FBSiwude9_2Game()
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
         var _loc4_:MovieClip = null;
         var _loc1_:DisplayObjectContainer = this.sceneInfo.scene.backGround;
         var _loc2_:int = 0;
         while(_loc2_ < 2)
         {
            _loc3_ = _loc1_.getChildByName("ant_" + _loc2_) as MovieClip;
            _loc3_.mouseChildren = false;
            _loc4_ = _loc1_.getChildByName("hand_" + _loc2_) as MovieClip;
            _loc4_.mouseChildren = false;
            _loc4_.mouseEnabled = false;
            this.ants.push(_loc3_);
            this.hands.push(_loc4_);
            _loc2_++;
         }
      }
      
      private function initFuns() : void
      {
         var _loc1_:MovieClip = null;
         for each(_loc1_ in this.ants)
         {
            _loc1_.buttonMode = true;
            _loc1_.addEventListener(MouseEvent.CLICK,this.onClickAnt);
         }
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
      
      private function onClickAnt(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         var _loc3_:int = this.ants.indexOf(_loc2_);
         this.ipf.fightInCopy(petIds[_loc3_]);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc3_:int = 0;
         var _loc2_:int = int(param1.id);
         if(param1.isWin)
         {
            ++this.fightedCount;
            _loc3_ = petIds.indexOf(_loc2_);
            this.killAnt(_loc3_);
            this.destroyHand(_loc3_);
         }
      }
      
      private function killAnt(param1:int) : void
      {
         var _loc2_:MovieClip = this.ants[param1] as MovieClip;
         if(null == _loc2_)
         {
            return;
         }
         _loc2_.buttonMode = false;
         _loc2_.mouseEnabled = false;
         _loc2_.removeEventListener(MouseEvent.CLICK,this.onClickAnt);
         TweenMax.to(_loc2_,1.6,{"colorMatrixFilter":{"saturation":0}});
         this.ants[param1] = null;
      }
      
      private function destroyHand(param1:int) : void
      {
         var hand:MovieClip = null;
         var index:int = param1;
         hand = this.hands[index] as MovieClip;
         hand.addFrameScript(hand.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(hand);
            checkEnd();
         });
         hand.gotoAndPlay(2);
      }
      
      private function checkEnd() : void
      {
         if(this.fightedCount >= 2)
         {
            this.movieFinish(-1,this.type);
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this.ants.length)
         {
            this.killAnt(_loc1_);
            _loc1_++;
         }
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
   }
}

