package mmo.house.b020000
{
   import mmo.play.scene.DocSceneBase;

   /** REBUILT document class of furniture/b020000.swf, the 动物园 (house 20000), on the later copy's art. */
   public class DocZooRevived extends DocSceneBase
   {
      public function DocZooRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         _scene = new ZooRevived();
      }
   }
}
