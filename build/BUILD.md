# Building the game

Step 1. [Install git-scm](https://git-scm.com/downloads) if you don't have it already.

Step 2. [Install Haxe](https://haxe.org/download/)

Step 3. [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/)

Step 4. Run these commands to install the libraries required:

```
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install flixel-addons
haxelib git linc_luajit https://github.com/Leather128/linc_luajit.git
haxelib git hscript-improved https://github.com/FNF-CNE-Devs/hscript-improved
haxelib git scriptless-polymod https://github.com/swordcube/scriptless-polymod
haxelib install hxCodec
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git flixelTextureAtlas https://github.com/Smokey555/Flixel-TextureAtlas.git
haxelib git fnf-modcharting-tools https://github.com/TheZoroForce240/FNF-Modcharting-Tools
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate
haxelib git hxNoise https://github.com/whuop/hxNoise
haxelib install flixel-screenshot-plugin
haxelib install hxcpp-debug-server
```

Dependencies for compiling:

## Windows

Install Visual Studio Community 2019, and while installing instead of selecting the normal options, only select these components in the 'individual components' instead (or the closest equivalents).

```txt
* MSVC v142 - VS 2019 C++ x64/x86 build tools
* Windows 10 SDK (Latest)
```

## Linux (if you decide to try and use hxCodec while compiling which requires changes at the moment)

In your package manager, install the following packages:

```sh
sudo apt-get install libvlc-dev
sudo apt-get install libvlccore-dev
sudo apt-get install vlc-bin
sudo apt-get install luajit
``` (APT Example)

```sh
sudo pacman -S vlc
sudo pacman -S luajit
``` (Pacman Example)

```
Step 5. Run `lime test [platform]` in the project directory while replacing '[platform]' with your build target (usually `html5`, `windows`, `linux`, `mac`, or whatever platform you are building for).
```
