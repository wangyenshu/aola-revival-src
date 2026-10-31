package mmo.game.parkour.game.avatar
{
   import flash.system.ApplicationDomain;
   import mmo.loader.CustomLoader;
   import mmo.loader.CustomLoaderEvent;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.scheduler.ResPriority;
   
   public class AvatarLoader
   {
      
      private static const AVATAR_ROLE_VIEW_ULR:String = "game/parkour/avatar/role";
      
      private static const AVATAR_RIDE_VIEW_URL:String = "game/parkour/avatar/ride";
      
      private static const AVATAR_ROLE_SKILL_MOVIE:String = "game/parkour/avatar/skill/skillmovie";
      
      private var _currentDomain:ApplicationDomain;
      
      private var _customLoader:CustomLoader;
      
      private var _callBack:Function;
      
      public function AvatarLoader()
      {
         super();
      }
      
      public function get currentDomain() : ApplicationDomain
      {
         return this._currentDomain;
      }
      
      public function loadAvatarRes(param1:AvatarResInfo, param2:Function) : void
      {
         this._currentDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
         var _loc3_:CustomLoader = new CustomLoader(ResPriority.NORMAL,true,this.currentDomain);
         this._customLoader = _loc3_;
         this._callBack = param2;
         _loc3_.addEventListener(CustomLoaderEvent.onLoadCompleted,this.onLoadResult);
         _loc3_.addEventListener(CustomLoaderEvent.onCancel,this.onLoadResult);
         _loc3_.addEventListener(CustomLoaderEvent.onError,this.onLoadResult);
         var _loc4_:Array = [AVATAR_ROLE_VIEW_ULR + param1.roldId,AVATAR_RIDE_VIEW_URL + param1.rideId];
         _loc3_.load(_loc4_,LoadingSpriteType.DIALOG_WITHOUT_CANCLE);
      }
      
      private function onLoadResult(param1:CustomLoaderEvent) : void
      {
         this.closeLoader();
         if(param1.type == CustomLoaderEvent.onLoadCompleted)
         {
            if(this._callBack != null)
            {
               this._callBack.apply(null,[this.currentDomain]);
            }
         }
      }
      
      private function closeLoader() : void
      {
         if(this._customLoader != null)
         {
            this._customLoader.close();
            this._customLoader.removeEventListener(CustomLoaderEvent.onLoadCompleted,this.onLoadResult);
            this._customLoader.removeEventListener(CustomLoaderEvent.onCancel,this.onLoadResult);
            this._customLoader.removeEventListener(CustomLoaderEvent.onError,this.onLoadResult);
            this._customLoader = null;
         }
      }
      
      public function dispose() : void
      {
         this.closeLoader();
         this._callBack = null;
         this._currentDomain = null;
      }
   }
}

