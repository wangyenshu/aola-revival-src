// Front-end settings for the winter 2012/13 client (copied into dist/ by the build).
window.AOLA_CONFIG = {
  // Entry SWF at its ORIGINAL URL; the service worker serves it from files/.
  // The winter 2012/13 client (manifest release 2013-01-25) lived on www.9aola.com;
  // play.html there embedded start.swf with this version stamp.
  bootUrl: "http://www.9aola.com/start.swf?120830",
  // Extra FlashVars from the captured play page's <embed>/<object>.
  flashvars: {},
  // The original play page's scripts (served from the mirror). They provide the
  // functions the client calls through ExternalInterface: getQS, isReg, getU, ...
  pageScripts: ["http://www.9aola.com/qs.js?20100929", "http://www.9aola.com/js/aola.js?20121227"],
  // The play page embedded the movie as id "myFlash" / name "myFlashEmbed".
  playerId: "myFlash",
  // Base for relative loads, as on the original page.
  base: "http://www.9aola.com/",
  // Original stage size (check the captured page; many games of the era used 960x560).
  width: 960,
  height: 560,

  // Hosts the service worker answers from the mirror.
  hosts: ["www.9aola.com", "web.9aola.com", "login.9aola.com", "service.9aola.com", "aola.100bt.com", "www.100bt.com", "service-aola.100bt.com"],
  // Where the game files are, relative to this page: the static build puts
  // them under files/ and lists them in files/index.json (scripts/build-static.mjs).
  mirror: "files/",
  index: "files/index.json",

  // Game servers the 2012 client connects to (host and port as the client
  // sees them; read them from recon.md or the client's server-list response).
  sockets: [{ host: "127.0.0.1", port: 9339 }],
  // The rebuilt login connects to 127.0.0.1:9339 and speaks the 2013 protocol.
  protocol: "sfs2013",
  // "inpage": the emulator runs inside this page (fully offline, saves in IndexedDB).
  // "server": sockets go to the Node server's WebSocket bridge (/__socket/<port>).
  mode: "inpage",

  // Game clock anchor (China time) and stream framing, as in the Node server.
  date: "2012-08-15",
  framing: "raw",
  verbose: true,
};
