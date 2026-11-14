package mmo.revival
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.interfaces.pet.peticon.PetIconContainer;

   /**
    * A 亚比's picture container by way of the picture service (PetIconService): the 2013
    * PetIconContainer made directly shows 兔小子 for every 亚比 its list leaves out (the ids
    * after 1426, 拉贝尔幻影 999 …); the service gives those their own picture (LaterPetIcon).
    * Without the service, the plain container.
    */
   public class RIcon
   {
      public static function container(viewId:int, type:int, load:Boolean):PetIconContainer
      {
         try
         {
            var s:IPetIcon = ServiceContainer.getService("PetIconService") as IPetIcon;
            if (s != null) return s.getPetIcon(viewId, type, load);
         }
         catch (e:Error) {}
         return new PetIconContainer(viewId, type, load);
      }
   }
}
