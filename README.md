# hxcross

*cross compile your hxcpp projects to various platforms from Linux*

## Supported targets

* iOs
* Mac OSX

## How it works

The clang toolchain is [a cross-compiler out-of-the-box](http://clang.llvm.org/docs/CrossCompilation.html). 
It needs however some tools - mainly the `binutils` toolchain - to be able to succesfully assemble and generate a binary file.
Happily, apple's `cctools` is open-source, and some [awesome](https://code.google.com/p/ios-toolchain-based-on-clang-for-linux/)
[folks](https://github.com/tpoechtrager/cctools-port) have been working to port it to Linux.

This project is a utility that sits on top of these to better manage your SDK installations and to play
nicely with hxcpp. The goal is to expose a simple interface and work as most out-of-the-box as possible.

## Getting started

Once you have your Haxe/Hxcpp* environment setup, install hxcross by running
```bash
haxelib git hxcross https://github.com/waneck/hxcross.git
haxelib run hxcross setup
```
You will be asked for your sudo password if you've chosen the default prefix (recommended)
After that, typing `hxcross` should bring the help menu.

*\* big warning: you will need to run the latest Haxe and Hxcpp in order to use this. We may later backport it to the older versions*

## Installing a toolchain

The next step is to install a new toolchain. You can do this with the `hxcross install` command. By running it without arguments,
you can see the currently available toolchains:

```bash
$ hxcross install

ERROR: Missing arguments
  --ios-toolchain   Installs an ios toolchain based on clang
  --mac-toolchain   Installs a mac toolchain based on clang
```

So if you want to install the ios toolchain, just write

```bash
hxcross install --ios-toolchain
```

The installation should be automatic on recent ubuntu/debian and arch-linux distributions. For others, you may need to install
some libs yourself. You are welcome to contribute back the libraries needed to install the toolchain on your distro!

## Installing an SDK

Installing the toolchain isn't enough to be able to compile any project; You still need the SDK, which has the includes, libs and
support files needed to correctly compile and link your executable.

In order to do this, you will need a Xcode .DMG file. The automatic extractor was only tested on the latest versions, but if you
have an apple developer account, you can also download the older xcode .dmg file.

Once you have a .dmg file, you can run
```bash
hxcross --install-sdk /path/to/xcode.dmg
```

And let hxcross automagically handle this for you!

Mounting dmg files on linux however can go wrong, so you may need a Mac to open the files and extract the .sdk directories,
and copy them back to your computer.

Once this is setup, you can confirm that the sdk was installed by running `hxcross -l`.

You can also specify the sdk version manually by passing an extra parameter: `hxcross --install-sdk /path/to/some/sdk MacOSX10.8.sdk`

## Cross-compiling!

After installing a toolchain and an sdk, you can start cross-compiling with hxcpp:

```haxe
class Main
{
	public static function main()
	{
		trace("Hello from Linux! Natively!");
	}
}
```

compile with:
```
-main Main
-cpp cpp
-lib hxcross
# replace here by -D ios-target to target ios instead!
-D mac-target
```

And tada!
![first mac binary!](/extra/assets/readme-1.png?raw=true)

You'll have your first mac binary!

### Cross compiling to iOs

Unlike the main hxcpp toolchain for ios, the default linkage for ios is an actual executable. This means that you can compile
the above code and generate a command-line executable for ios.
Of course, GUI-able apps can also be generated - if you for example link to NME or OpenFL from within your app. But lets' leave that for later.

Command-line apps can only be executed in a jailbroken device. And because nobody has yet ported apple's `codesign` application to Linux,
you will either still need a mac to codesign your apps, or you will need a jailbroken device to disable the code signing need.

So let's go to our example again:

```haxe
class Main
{
	public static function main()
	{
		trace("Hello from Linux! Natively!");
	}
}
```

compile with:
```
-main Main
-cpp cpp
-lib hxcross
-D ios-target
```

This will generate a `cpp/Main` executable. In order to run it, you will need to enable `OpenSSH` on your jailbroken device, and use
`scp` to copy it there. But **before you copy**, you still need to "fake sign" your app using ldid:

```bash
ldid -S cpp/Main
```

After this is done, just copy the executable to your device and execute it:

```bash
$ scp cpp/Main mobile@<ios-ip>:~/
$ ssh mobile@<ios-ip>
$ ./cpp/Main
```

You should get a warm hello from Linux!

Please pay attention to the sdk version you're compiling to - you can never use a SDK that is newer than the SDK on your device.


## Contributing

This is a proof-of-concept and needs some work to actually become a good alternative to iOs development. Its architecture is still
very unstable, and I'd be happy to discuss changing it. If you're interested in helping, this project needs it :)
