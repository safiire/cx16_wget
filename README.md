# Intro
CX16 Wget is a program that will allow you to download files over the HTTP, HTTPS, FTP, and Gopher protocols to your Commander X16 SDCard.

It uses the capabilities provided by the [Commander X16 921.6Kbps Serial & ESP32 Network Card](https://texelec.com/product/commander-x16-serial-network-card/) and Bo Zimmerman's [ZiModem](https://github.com/bozimmerman/Zimodem) which comes installed as firmware on the card.

This program is useful for developing software on your PC, so you can compile or assemble your projects on your PC, and easily transfer them to the Commander X16 to test on the real hardware, and this is the purpose I originaly created it to serve.

Of course it's also useful for copying any file from your LAN or internet onto the SDCard, yay.

You can download anything you want over the above protocols from your LAN or from the wider internet, provided you have the network card, and it is less than 2GiB, I hope helps open the CX16 up to the internet.

# Getting Started

Grab the latest release from Releases area, and copy `wget.prg` somewhere onto your Commander X16's SDCard.

Take a moment to bask as you realize you may not need to ever do this SDCard dance again, or at least not every time you want to copy files to it.

Put the SDCard back in, and when you boot up the CX16, choose a URI you'd like to download, and the output file name to save.

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
                   github.com/safiire
======================================
Usage: run:rem <uri> [@:]<output file>
```

This program uses a trick to allow "commandline arguments" to a program from BASIC, so you can specify the URI you'd like to download and the file you'd like to save its contents to.

You provide a BASIC comment (rem) after the `RUN` command, which CX16 Wget reads to find the URI and output file.

```
run:rem https://irkenkitties.com/favicon.ico phi.ico
```

Typing this you should see something similar to:

```
======================================
CX16 wget                      v2.0.0
                 codeberg.org/safiire
======================================
[+] Enabled Auto-TX
[+] Detected uart at 9FC0
[I] Fetching...
[+] 00003aee bytes left
[*] Done in 00000049 Jiffies
[+] Resetting ZiModem... Ok

ready.

```

Now the file should appear on your SDCard, for example if you push F7 You'll see it in your directory listing.

One limitation currently is that this supports only files up to 2GiB, and if you attempt to download a larger file, it will abort and let you know.

Since spaces are used to group the commandline arguments, if your URI has spaces in it, please replace spaces with %20.

# Roadmap
- [ ] Better UART and ZiModem port detection
- [ ] Stop using himem, there's no need
- [ ] Detect your current baud rate, and temporarily change it to 921600 baud (2.1.0)
- [ ] For those with multiple UARTs, allow you to specify a UART other than the first found (2.2.0)

# Contributing

I welcome any contributions to improve CX16 Wget, improve the speed or usability.  Please create an Issue or PR with your complaints/suggestions, I'm happy to see them.

# License

This software is released under the GPL3 license

# Contact

Please contact via Issues, PRs, discord, or via email with the domain listed in these docs that you figure out yourself.
