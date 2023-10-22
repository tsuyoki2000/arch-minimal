# arch-minimal

## ISO ダウンロード
https://www.archlinux.jp/download/

「archlinux-日付-x86_64.iso」をダウンロードする（日付はリリース日）

## スクリプトの説明
VirtualBox 用スクリプト

ISO から起動後、
```
# loadkeys jp106
# curl -O https://raw.githubusercontent.com/tsuyoki2000/arch-minimal/main/install.sh
# bash arch-minimal-install.sh
```
1. インストールが終わったら、シャットダウン。
2. ISO を除去し、起動。

ログイン後
```
$ sudo localectl set-keymap jp106
```

## ターミナル（tty）の文字化け
日本語環境にしたので、２バイト文字は文字化けする。

以下のコマンドで一時的に英語にする。
```
$ export LANG=C
```
