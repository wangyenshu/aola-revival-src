// The launcher of a mod exported as a game of its own, for Windows (tools/mod-sdk/export.mjs
// --exe): one program with the exported site inside it (site/, embedded when it is built). Run, it
// serves the site on this computer only (127.0.0.1) and opens it in the default browser: the game
// plays there, offline, as the exported website does. Its window stays open while the game is
// played; closing it ends the game.
//
// The port is the mod's own (meta.go, from the mod's id): the browser keeps the game's progress
// for that address, so it is there again the next time. Started twice, the second only opens the
// browser again.
package main

import (
	"embed"
	"fmt"
	"io"
	"io/fs"
	"mime"
	"net"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

//go:embed all:site
var site embed.FS

func main() {
	setConsole(title)
	root, err := fs.Sub(site, "site")
	if err != nil {
		fail(err)
	}
	// The types the game's files need whatever the computer's own table says (Windows may call
	// .js text/plain, and Ruffle wants application/wasm).
	for ext, t := range map[string]string{
		".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".json": "application/json; charset=utf-8",
		".css": "text/css; charset=utf-8", ".txt": "text/plain; charset=utf-8", ".wasm": "application/wasm", ".svg": "image/svg+xml",
		".png": "image/png", ".jpg": "image/jpeg", ".gif": "image/gif", ".mp3": "audio/mpeg", ".swf": "application/x-shockwave-flash",
		".xml": "text/xml; charset=utf-8",
	} {
		_ = mime.AddExtensionType(ext, t)
	}
	addr := "127.0.0.1:" + port
	url := "http://" + addr + "/"
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		// Already running (started twice)? Then only the browser again.
		if ours(url) {
			fmt.Println(title + " 已经在运行了，正在浏览器里打开……")
			openBrowser(url)
			time.Sleep(2 * time.Second)
			return
		}
		// The port taken by something else: another one (the progress kept for the mod's own
		// address is not there).
		if ln, err = net.Listen("tcp", "127.0.0.1:0"); err != nil {
			fail(err)
		}
		url = "http://" + ln.Addr().String() + "/"
		fmt.Println("端口 " + port + " 被别的程序占用了，这次换了一个端口（之前的游戏进度在原来的端口上，这次看不到）。")
	}
	files := http.FileServer(http.FS(root))
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// The page and its scripts fresh each time (a newer launcher of the same mod brings newer ones).
		if p := r.URL.Path; p == "/" || strings.HasSuffix(p, ".html") || strings.HasSuffix(p, ".js") || strings.HasSuffix(p, ".json") {
			w.Header().Set("Cache-Control", "no-cache")
		}
		files.ServeHTTP(w, r)
	})
	fmt.Println(title)
	fmt.Println()
	fmt.Println("游戏正在浏览器里打开：" + url)
	fmt.Println("玩的时候请不要关闭这个窗口；关闭它，游戏就停止了。")
	fmt.Println("（浏览器没有自己打开的话，把上面的地址复制到浏览器里。）")
	go func() {
		time.Sleep(400 * time.Millisecond)
		openBrowser(url)
	}()
	if err := http.Serve(ln, handler); err != nil {
		fail(err)
	}
}

// ours: what answers at url is this mod's game (its config names the mod).
func ours(url string) bool {
	c := http.Client{Timeout: 2 * time.Second}
	res, err := c.Get(url + "config.js")
	if err != nil {
		return false
	}
	defer res.Body.Close()
	b, _ := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	return strings.Contains(string(b), modFile)
}

func openBrowser(url string) {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
	case "darwin":
		cmd = exec.Command("open", url)
	default:
		cmd = exec.Command("xdg-open", url)
	}
	_ = cmd.Start()
}

func fail(err error) {
	fmt.Println("出错了：", err)
	fmt.Println("按回车键关闭。")
	fmt.Fscanln(os.Stdin)
	os.Exit(1)
}
