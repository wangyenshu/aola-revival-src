package mmo.plantdecorator
{
   import mmo.houseinterfaces.decorate.IHouseDecorator;
   import mmo.houseinterfaces.material.HouseItemTypes;
   import mmo.houseinterfaces.material.MaterialLayoutInfo;
   import mmo.houseinterfaces.material.MaterialLayoutState;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.houseinterfaces.operate.StorageTableTypes;
   import mmo.interfaces.material.UserMaterial;
   import mmo.interfaces.material.plant.UserPlant;

   /** REBUILT (as the later plantdecorator's): a tree made furniture, with where it stands. */
   public class UserPlantWrap extends UserMaterialWrap
   {
      public function UserPlantWrap(p:UserPlant, parent:IHouseDecorator)
      {
         super(p, parent);
         storageTableType = StorageTableTypes.Normal;
      }

      public function get userPlant():UserPlant
      {
         return userMaterial as UserPlant;
      }

      override public function get itemType():int
      {
         return HouseItemTypes.FLOOR;
      }

      /** Saved: where it stands now (or back in the storage). */
      override public function acceptChanges():void
      {
         var changes:Array = getChanges();
         if (changes.length > 0)
         {
            var l:MaterialLayoutInfo = changes[0] as MaterialLayoutInfo;
            userPlant.houseId = l.state == MaterialLayoutState.Deleted ? 0 : l.houseId;
            userPlant.x = l.state == MaterialLayoutState.Deleted ? 0 : l.x;
            userPlant.y = l.state == MaterialLayoutState.Deleted ? 0 : l.y;
         }
         userMaterial.setValue(UserMaterial.propertyUseUp, userMaterial.usedUp + changeCount);
         super.acceptChanges();
      }

      /** Another house type: back in the storage. */
      public function clearOnResetHouse():void
      {
         userPlant.houseId = 0;
         userPlant.x = 0;
         userPlant.y = 0;
         userMaterial.setValue(UserMaterial.propertyUseUp, 0);
      }
   }
}
