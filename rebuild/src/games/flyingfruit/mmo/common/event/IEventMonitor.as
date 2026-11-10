package mmo.common.event
{
   internal interface IEventMonitor
   {
      
      function getAllListenersCount() : Object;
      
      function getAllListenersCountString() : String;
   }
}

