package mmo.thinktower.interact
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.bubble.BubbleUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePetAvatar;
   import mmo.play.scene.SceneManager;
   
   public class FightInteract implements Iinteract
   {
      
      private var fun:Function;
      
      private var params:Array;
      
      private var myplayer:PlayerBase;
      
      private var scenepetavater:ScenePetAvatar;
      
      private var overLap:Sprite;
      
      public function FightInteract()
      {
         super();
      }
      
      public function initInterrace(param1:Array, param2:Function) : void
      {
         this.params = param1;
         this.fun = param2;
         this.scenepetavater = new ScenePetAvatar(param1[1] % 10000,new Point(0,0));
         this.scenepetavater.setStrategy(null);
         MovieClip(param1[0]).alpha = 0;
         this.scenepetavater.x = MovieClip(param1[0]).x;
         this.scenepetavater.y = MovieClip(param1[0]).y;
         BubbleUtil.instance.addBubble(param1[0],param1[4],MovieClip(param1[0]).x,MovieClip(param1[0]).y - 50);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.scenepetavater);
         MovieClip(param1[0]).addEventListener(Event.ENTER_FRAME,this.onEnterframe);
         this.myplayer = PlayerManager.getInstance().myPlayer;
      }
      
      private function onEnterframe(param1:Event) : void
      {
         if(MovieClip(this.params[0].mc0).hitTestPoint(this.myplayer.x,this.myplayer.y))
         {
            this.myplayer.jumpTo(Point(this.params[2]).x,Point(this.params[2]).y);
            this.fightwithpm();
         }
         else if(MovieClip(this.params[0].mc1).hitTestPoint(this.myplayer.x,this.myplayer.y))
         {
            this.myplayer.jumpTo(Point(this.params[3]).x,Point(this.params[3]).y);
            this.fightwithpm();
         }
      }
      
      private function fightwithpm() : void
      {
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFail);
         _loc1_.fightWithTaskPet(this.params[1],this.getPetLevel());
      }
      
      private function getPetLevel() : int
      {
         var _loc5_:PetBriefInfo = null;
         var _loc1_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var _loc2_:Array = _loc1_.getMyPets();
         var _loc3_:int = 1;
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc5_ = _loc2_[_loc4_] as PetBriefInfo;
            _loc3_ = _loc5_.level > _loc3_ ? int(_loc5_.level) : _loc3_;
            _loc4_++;
         }
         return _loc3_;
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFail);
         if(this.fun != null)
         {
            this.fun.apply(null,[param1.isWin]);
         }
         if(param1.isWin)
         {
            MovieClip(this.params[0]).removeEventListener(Event.ENTER_FRAME,this.onEnterframe);
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.params[0]);
            BubbleUtil.instance.removeBubble(this.params[0]);
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.scenepetavater);
         }
         else
         {
            BubbleUtil.instance.removeBubble(this.params[0]);
            BubbleUtil.instance.addBubble(this.params[0],this.params[5],MovieClip(this.params[0]).x,MovieClip(this.params[0]).y - 50);
         }
      }
      
      private function onEnterFightFail(param1:PetFightEvent) : void
      {
         var _loc2_:Boolean = false;
         if(this.fun != null)
         {
            this.fun.apply(null,[_loc2_]);
         }
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFail);
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFail);
         MovieClip(this.params[0]).removeEventListener(Event.ENTER_FRAME,this.onEnterframe);
         this.params = null;
      }
   }
}

