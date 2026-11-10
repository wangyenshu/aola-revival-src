package mmo.superevolution
{
   import mmo.framework.comm.SocketClient;

   /** The 2015 module's command (PetExtension2 54e_1 {pid, t} -> {res}, 0 done; server superevo.ts). */
   internal class MyClient
   {
      public static const cmdEEvolution4shape:String = "54e_1";

      private static const extensionName:String = "PetExtension2";

      public static function evolution(pid:int, t:int = 1):void
      {
         SocketClient.instance.sendXtMessage(extensionName, cmdEEvolution4shape, {pid: pid, t: t});
      }
   }
}
