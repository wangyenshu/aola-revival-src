package mmo.game.parkour.game.avatar
{
   public class AvatarActionCodeHelper
   {
      
      public static const RUN:String = "run";
      
      public static const JUMP_UP:String = "jump_up";
      
      public static const JUMP_DOWN:String = "jump_down";
      
      public static const JUMP_ON_AIR:String = "jump_on_air";
      
      public static const SLIP:String = "slip";
      
      public static const SPRINT:String = "sprint";
      
      public static const ROLE_NORMAL:String = "role_normal";
      
      public static const ROLE_SKILL:String = "role_skill";
      
      public function AvatarActionCodeHelper()
      {
         super();
      }
      
      public static function createDefaultCodes() : Array
      {
         return [RUN,JUMP_UP,JUMP_DOWN,JUMP_ON_AIR,SLIP,SPRINT];
      }
   }
}

