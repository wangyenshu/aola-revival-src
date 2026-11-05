// 百田大剧场: the page functions the January 2013 client calls through
// ExternalInterface. The original page script (js/aola.js) put an iframe of
// 百田's video site over the game: showVideoPlayer (the theatre scene) its
// list of cartoons, showAnniversaryVideo the 奥拉星2周年 film,
// showWarTeamVideo the 战队 film. v.100bt.com is gone; these open the game's
// own theatre (control/TheatrePanel, which plays the surviving FLVs in
// Ruffle) through its revivalTheatre callback. boot.js calls install() once
// the page scripts have loaded.
(() => {
  // Later: the call comes from inside the game, which cannot be called back into then.
  const tell = (film) =>
    setTimeout(() => {
      const p = window.aolaPlayer;
      try {
        if (p && typeof p.revivalTheatre === "function") p.revivalTheatre(film);
        else console.warn("[theatre] the game is not ready");
      } catch (e) {
        console.warn("[theatre]", e);
      }
    }, 0);

  function install() {
    window.showVideoPlayer = () => tell("");
    window.showAnniversaryVideo = () => tell("anniversary2");
    window.showWarTeamVideo = () => tell("warteam");
    window.clearVideoPlayer = () => tell("close");
    window.clearDiv = () => tell("close");
  }

  window.AolaTheatre = { install };
})();
