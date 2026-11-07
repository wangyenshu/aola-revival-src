package mmo.thinktower.interact
{
   import mmo.interfaces.thinktower.TowerInteractType;
   
   public class InteractFactory
   {
      
      private static var _instance:InteractFactory;
      
      public function InteractFactory()
      {
         super();
      }
      
      public static function get getInstance() : InteractFactory
      {
         if(_instance == null)
         {
            _instance = new InteractFactory();
         }
         return _instance;
      }
      
      public function getInteract(param1:int) : Iinteract
      {
         switch(param1)
         {
            case TowerInteractType.CLICK:
               return new ClickInteract();
            case TowerInteractType.FIGHT:
               return new FightInteract();
            case TowerInteractType.SHOOT:
               return new ShootInteract();
            case TowerInteractType.TIMER:
               return new TimerInteract();
            case TowerInteractType.ICEWALK:
               return new IceWalkInteract();
            case TowerInteractType.THUNDERSEND:
               return new ThunderSendInteract();
            case TowerInteractType.PLAYMOVIE:
               return new MoviePlayInteract();
            default:
               throw new Error("类型错误！！");
         }
      }
   }
}

