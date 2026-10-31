package mmo.game.parkour.game.interfaces
{
   public interface IParkourRoleSkill
   {
      
      function init(param1:Object) : void;
      
      function validate() : Boolean;
      
      function excute(param1:Object) : void;
   }
}

