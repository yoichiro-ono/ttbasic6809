豊四季タイニーBASIC for 6809

本プログラムは、オリジナル版「TOYOSHIKI Tiny BASIC for Arduino」を6809用に移植したバージョンです。

移植時には手作業でアセンブリ言語にコンバートしています。

​ オリジナル版配布サイト https://github.com/vintagechips/ttbasic_arduino
​ 関連情報 電脳伝説 Vintagechips - 豊四季タイニーBASIC確定版


対応ハードウェア

​SBC6809
 https://vintagechips.wordpress.com/2017/10/16/6809が動いた/

 ※CPUに6809(および互換CPU)を使用し、シリアル入出力にACIA(6850および互換チップ)と、
   4kb程度のROM、および、8kb程度のRAMを搭載した機器であれば上記以外でも簡単に動作します
   環境依存部分は「ttbasic_def.asm」に集めています


利用環境

​ターミナルソフト (TeraTerm を推奨、Windows 10等のプラットフォームを含む）

主な特徴

​手作業でアセンブリ言語に移植したためCコンパイラでコンパイルしたものよりは
 多少は良いコードになっている
 
 (つもりだが6809アセンブリの勉強のために手作業で移植したため効率の悪い部分が多々ある)

​シリアル入力にリングバッファを使用し、バッファの残量でRTS制御を行っている

 そのため、PCからのデータ送信に処理が追い付かない場合でもデータの取りこぼしが起こらないので
 ターミナルソフトで文字間・行間の送信遅延の設定は必要ない
 
​オリジナル版に合わせて機能追加を行いやすいように移植している

(つもり)

​バグがたくさん残っている


本プログラムに実装において、下記公開ソースの一部を流用しています。

​http://www.retroprogramming.com/2017/07/xorshift-pseudorandom-numbers-in-z80.html


 Xorshift 16bit
 
 ※Z80から6809にコンバートしています。

​https://perso.b2b2c.ca/~sarrazip/dev/cmoc.html
 
 DIV16.asm,MUL16.asm

​アセンブルにはasm6809を使用してください

 http://www.6809.org.uk/asm6809/

 asm6809 -9 -B -o ttbasic6809.bin -l ttbasic6809.lst ttbasic6809.asm



以下はオリジナル版のドキュメントです。

```
﻿TOYOSHIKI Tiny BASIC for Arduino

The code tested in Arduino Uno R3.
Use UART terminal, or temporarily use Arduino IDE serial monitor.

Operation example
> list
10 FOR I=2 TO -2 STEP -1; GOSUB 100; NEXT I
20 STOP
100 REM Subroutine
110 PRINT ABS(I); RETURN

OK
>run
2
1
0
1
2

OK
>

The grammar is the same as
PALO ALTO TinyBASIC by Li-Chen Wang
Except 3 point to show below.

(1)The contracted form of the description is invalid.

(2)Force abort key
PALO ALTO TinyBASIC -> [Ctrl]+[C]
TOYOSHIKI TinyBASIC -> [ESC]
NOTE: Probably, there is no input means in serial monitor.

(3)Other some beyond my expectations.

(C)2012 Tetsuya Suzuki
GNU General Public License
```
