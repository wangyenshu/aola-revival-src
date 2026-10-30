package mmo.housedecorator
{
   import flash.geom.Point;
   import mmo.houseinterfaces.decorate.IHouseDecorator;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.interfaces.material.UserMaterial;
   import mmo.interfaces.material.furniture.Furniture;
   import mmo.interfaces.material.furniture.UserFurniture;

   /** REBUILT. A furniture item the player owns, with the places it is put (UserMaterialWrap). */
   public class UserFurnitureWrap extends UserMaterialWrap
   {
      public function UserFurnitureWrap(uf:UserFurniture, parent:IHouseDecorator)
      {
         super(uf, parent);
         storageTableType = Furniture(uf.material).storageTableType;
      }

      override public function get itemType():int
      {
         return Furniture(material).type;
      }

      override public function get fixPoint():Point
      {
         var f:Furniture = Furniture(material);
         return new Point(f.fixX, f.fixY);
      }

      /** Saved: what is now placed counts as used up. */
      override public function acceptChanges():void
      {
         userMaterial.setValue(UserMaterial.propertyUseUp, userMaterial.usedUp + changeCount);
         super.acceptChanges();
      }

      /** After the house type changed every item is back in the storage, except the new house itself. */
      public function clearOnResetHouse(newHouseId:int):void
      {
         userMaterial.setValue(UserMaterial.propertyUseUp, materialId == newHouseId ? 1 : 0);
      }
   }
}
