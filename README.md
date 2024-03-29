# TekBASE - Installscript for Linux
![TekBASE 8.X](https://img.shields.io/badge/TekBASE-8.X-green.svg) ![License GNU AGPLv3](https://img.shields.io/badge/License-GNU_AGPLv3-blue.svg) [![Codacy Badge](https://app.codacy.com/project/badge/Grade/ab465eb926c04d3db4ce13c814b9e81c)](https://www.codacy.com/gh/teklab-de/tekbase-installscript-linux/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=teklab-de/tekbase-installscript-linux&amp;utm_campaign=Badge_Grade)

Installation script with Debian, Ubuntu, OpenSuSE, Centos and Fedora support for the TekBASE server control panel. This script sets up your server completely. Apache, PHP, MySQL/MariaDB, ProFTP and Teamspeak can be installed with one click. It is checked whether Plesk, Confixx or ... is used on the server and configured accordingly. 

TekBASE is a server control panel software for clans, communities and service providers with an online shop, billing system, and reminder system. More informations about TekBASE at [TekLab.de](https://teklab.de)

## Installation
Under "Releases" you will find the download for your TekBASE version.

```
cd /home
git clone https://github.com/teklab-de/tekbase-installscript-linux.git
cd tekbase-installscript-linux
./webinstall.sh
```

## License
Copyright (c) TekLab.de. Code released under the [GNU AGPLv3 License](https://github.com/teklab-de/tekbase-installscript-linux/blob/master/LICENSE). The use by other commercial control panel providers is explicitly prohibited.
