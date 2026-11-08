//go:build windows

package main

import (
	"syscall"
	"unsafe"
)

// setConsole: the window's words in UTF-8 (a Chinese Windows' console is GBK otherwise) and its title.
func setConsole(title string) {
	k := syscall.NewLazyDLL("kernel32.dll")
	_, _, _ = k.NewProc("SetConsoleOutputCP").Call(65001)
	if p, err := syscall.UTF16PtrFromString(title); err == nil {
		_, _, _ = k.NewProc("SetConsoleTitleW").Call(uintptr(unsafe.Pointer(p)))
	}
}
