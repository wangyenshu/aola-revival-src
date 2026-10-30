package mmo.shoot.players.effects
{
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.play.player.dressily.Dressily;
   import mmo.play.player.dressily.DressilyEvent;
   import mmo.play.player.dressily.IDressily;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.socketserver.data.User;
   
   public class ReplaceEffect extends PlayerEffectBase
   {
      
      private var replaceDressily:IDressily;
      
      private var orgDressily:IDressily;
      
      public function ReplaceEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.orgDressily = Player(this.player).dressily;
         this.createDressily();
         this.orgDressily.avatarSprite.visible = false;
         var _loc1_:int = int(this.player.getChildIndex(this.orgDressily.avatarSprite));
         this.player.addChildAt(this.replaceDressily.avatarSprite,_loc1_ + 1);
         this.replaceDressily.avatarSprite.name = this.excludeKey;
      }
      
      private function createDressily() : void
      {
         var _loc1_:String = this.player.getName();
         var _loc2_:User = SocketClient.instance.activeRoom.getUser(_loc1_);
         var _loc3_:AvatarInfo = new AvatarInfo();
         _loc3_.setAvatarInfoWithString(this.params["clothes"].toString());
         this.replaceDressily = new Dressily(null,_loc3_);
         var _loc4_:String = "ddzn";
         var _loc5_:String = ScenePlayer(this.player).currentAction();
         if(_loc5_ != null && Boolean(isBaseAction(_loc5_)))
         {
            _loc4_ = _loc5_.substr(0,3) + "n";
         }
         this.replaceDressily.action(_loc4_);
         this.orgDressily.addEventListener(DressilyEvent.ACTION_BEGIN,this.onAction);
      }
      
      private function onAction(param1:DressilyEvent) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc2_:String = "ddzn";
         if(isBaseAction(param1.params.action))
         {
            _loc2_ = param1.params.action;
            _loc3_ = _loc2_.substring(0,3);
            _loc4_ = _loc2_.substring(_loc2_.length - 1);
            if(_loc4_ == "f" || _loc4_ == "r")
            {
               _loc2_ = _loc3_ + "n";
            }
         }
         this.replaceDressily.action(_loc2_);
      }
      
      /** Standing (..z.) or walking (..w.): the later ActionCodeHelper.isBaseAction for 2013 action codes. */
      private static function isBaseAction(param1:String) : Boolean
      {
         return param1 != null && param1.length == 4 && "zw".indexOf(param1.charAt(2)) >= 0;
      }

      override public function get excludeKey() : String
      {
         return "ReplaceEffect_" + this.params["targetEffect"].toString();
      }
      
      override public function clear() : void
      {
         var _loc1_:int = int(this.player.getChildIndex(this.replaceDressily.avatarSprite));
         this.player.removeChild(this.replaceDressily.avatarSprite);
         this.orgDressily.avatarSprite.visible = true;
         this.replaceDressily.dispose();
         this.replaceDressily = null;
         this.orgDressily.removeEventListener(DressilyEvent.ACTION_BEGIN,this.onAction);
         this.orgDressily = null;
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

