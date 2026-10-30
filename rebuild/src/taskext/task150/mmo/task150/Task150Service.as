package mmo.task150
{
   import mmo.interfaces.task.ext.TaskExtServiceBase;

   /** REBUILT taskext/task150: the task's service, as the later copy names it. */
   public class Task150Service extends TaskExtServiceBase
   {
      public function Task150Service()
      {
         super();
         resInitiallerDefines = [Task150Initialler];
      }
   }
}
