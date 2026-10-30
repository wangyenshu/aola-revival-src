package mmo.scenetalk
{
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.face.IFaceService;
   import mmo.interfaces.scenetalk.ISceneTalkService;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.Player;
   import mmo.socketserver.data.User;

   /**
    * REBUILT baseservice/scenetalk (ServiceConfig "SceneTalkService", locator
    * mmo.scenetalk.SceneTalkServiceLocator): chat in a scene. The 2013 module
    * is lost; written against the 2013 ISceneTalkService and SocketClient:
    * a line goes out as a room public message (SocketClient.sendPublicMessage,
    * "[PubMsg]"), every line heard (onPublicMessage) is shown in a bubble over
    * the speaker's head and kept in the last 30 lines; smile() sends an
    * "[Emote]", and a face heard is shown over the sender's head.
    */
   public class SceneTalkService extends EventDispatcher implements ISceneTalkService
   {
      public static const MAX_LENGTH:int = 40;

      private var _isTalkable:Boolean = true;
      private var _isSmilable:Boolean = true;
      private var _errCounter:int;
      private var active:Boolean;
      private var record:Array = [];

      public function SceneTalkService()
      {
         super();
      }

      public function init():void
      {
         activate();
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function activate():void
      {
         if (active) return;
         active = true;
         SocketClient.instance.addEventListener(SocketClientEvent.onPublicMessage, onPublicMessage);
         SocketClient.instance.addEventListener(SocketClientEvent.onEmote, onEmote);
      }

      public function deactivate():void
      {
         active = false;
         SocketClient.instance.removeEventListener(SocketClientEvent.onPublicMessage, onPublicMessage);
         SocketClient.instance.removeEventListener(SocketClientEvent.onEmote, onEmote);
      }

      public function say(text:String):void
      {
         if (!_isTalkable || text == null) return;
         text = text.replace(/[\r\n]/g, "").replace(/^\s+|\s+$/g, "");
         if (text == "") return;
         if (text.length > MAX_LENGTH) text = text.substr(0, MAX_LENGTH);
         SocketClient.instance.sendPublicMessage(text);
      }

      public function smile(face:int):void
      {
         if (_isSmilable) SocketClient.instance.sendEmote(String(face));
      }

      private function onPublicMessage(e:SocketClientEvent):void
      {
         var u:User = e.params.sender as User;
         var msg:String = String(e.params.message);
         if (u == null) return;
         var p:Player = PlayerManager.getInstance().playerList[u.getName()] as Player;
         if (p != null) p.say(msg);
         record.push({userName: u.getName(), message: msg});
         if (record.length > 30) record.shift();
      }

      /** "[Emote]<id>": the face (baseservice/face, FaceService.getFace) over the sender's head. */
      private function onEmote(e:SocketClientEvent):void
      {
         var u:User = e.params.sender as User;
         if (u == null) return;
         var name:String = u.getName();
         var id:int = int(e.params.face);
         ServiceContainer.instance.tryGetService("FaceService", function(svc:IFaceService, o:Object):void
         {
            svc.getFace(id, function(faceId:int, mc:MovieClip):void
            {
               var p:Player = PlayerManager.getInstance().playerList[name] as Player;
               if (p != null && mc != null) p.showFace(mc, 3);
            });
         });
      }

      public function getTalkMessageRec():Array
      {
         return record.concat();
      }

      public function set isTalkable(v:Boolean):void { _isTalkable = v; }
      public function get isTalkable():Boolean { return _isTalkable; }
      public function set isSmilable(v:Boolean):void { _isSmilable = v; }
      public function get isSmilable():Boolean { return _isSmilable; }
      public function incErrCounter():void { _errCounter++; }
      public function get errCounter():int { return _errCounter; }
   }
}
