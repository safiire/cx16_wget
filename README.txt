Content-Type: text/x-zim-wiki
Wiki-Format: zim 0.6
Creation-Date: 2026-04-23T17:59:30-07:00

# Intro
CX16 Wget is a program that will allow you to download files over the HTTP, HTTPS, FTP, and Gopher protocols to your Commander X16 SDCard.

It uses the capabilities provided by the [Commander X16 921.6Kbps Serial & ESP32 Network Card](https://texelec.com/product/commander-x16-serial-network-card/) and Bo Zimmerman's [ZiModem](https://github.com/bozimmerman/Zimodem) which comes installed as firmware on the card.

This program is useful for developing software on your PC, so you can compile or assemble your projects on your PC, and easily transfer them to the Commander X16 to test on the real hardware, and this is the purpose I originaly created it to serve.

You can download anything you want over the above protocols from your LAN or from the wider internet, provided you have the network card, and it is less than 2GiB, and helps open the CX16 up to the internet.

# Getting Started

Grab the latest release from Releases area, and copy `wget.prg` somewhere onto your Commander X16's SDCard.

Take a moment to bask as you realize you may not need to ever do this SDCard dance again, or at least not every time you want to copy files to it.

Put'er back in, and when you boot up the CX16, choose a URI you'd like to download, and the output file name to save.

If you put CX16 wget in your SDCard's root directory, in BASIC you'd write:

```
/wget.prg
```

Which will respond with something similar to this:

```
SEARCHING FOR WGET.PRG
LOADING FROM $0801 TO $110E
```

If you type:

```
run
```

You'll see output similar to this, letting you know the usage of the program:

```
======================================
CX16 wget                      v2.0.0
				 codeberg.org/safiire
======================================
Usage: run:rem <uri> [@:]<output file>
```

This program uses a trick to allow "commandline arguments" to a program from BASIC, so you can specify the URI you'd like to download and the file you'd like to save its contents to.

Basically, you provide a BASIC comment after the `RUN` command, which CX16 Wget reads.

```
run:rem https://irkenkitties.com/favicon.ico phi.ico
```





======================================
CX16 wget                      v2.0.0
				 codeberg.org/safiire
======================================
Usage: run:rem <uri> [@:]<output file>
```




# Installation

# Usage

# Roadmap

# Contributing

# License

# Contact
