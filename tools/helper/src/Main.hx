#if cpp
import hxcpp.StaticStd;
import haxe.io.Path;
import hxcpp.StaticZlib;
import hxcpp.StaticRegexp;
#end

import sys.FileSystem.*;
import apps.*;

using StringTools;
using Lambda;
/**
	Helper to install and run cross-compilers from Haxe.
 **/
class Main extends Cli
{
	static function main()
	{
		Sys.putEnv('PATH',Sys.getEnv('PATH') + ":$prefix/bin");
		var args = Sys.args();
		new mcli.Dispatch(args).dispatch(new Main());
	}

	/**
		Builds and installs a specific cross-compiler.

		@more Run `hxcross install --help` to see all options
	 **/
	public function install(d:mcli.Dispatch)
	{
		// check
		// clone repo ( https://github.com/tpoechtrager/cctools-port )
		d.dispatch(new Install(this));
	}

	private function getSdk()
	{
		if (sdk == null)
			sdk = Sys.getEnv('HXCROSS_SDK');
		if (sdk == null)
			sdk = 'ios';
		return sdk;
	}

	/**
		Runs a command using the sdk specified
	 **/
	public function run(d:mcli.Dispatch)
	{
		var info = sdkInfo(getSdk()),
			triple = info.triple;
		var args = d.args.splice(0,d.args.length);
		args.reverse();
		var add = [];
		var cmd = args.shift();

		switch (cmd)
		{
			case 'clang' | 'clang++' | 'ld':
				if (args.indexOf('-arch') < 0 && info.arch != '' && info.arch != 'arm')
				{
					add.push('-arch');
					add.push(info.arch);
				}

				if (verbose && args.indexOf('-v') < 0)
				{
					add.push('-v');
				}
		}
		switch (cmd)
		{
			case 'ld':
				if (args.indexOf('-syslibroot') < 0)
				{
					add.push('-syslibroot');
					add.push('$prefix/share/${info.name}${info.ver}.sdk');
				}
				if (args.indexOf('-lstdc++') < 0)
					add.push('-lstdc++');
				if (args.indexOf('-lSystem') < 0)
					add.push('-lSystem');
		}
		switch (cmd)
		{
			case null:

				Sys.stderr().writeString('hxcross run: Missing argument\n');
				Sys.exit(3);
			case 'clang' | 'clang++':
				if (args.indexOf('-isysroot') < 0)
				{
					add.push('-isysroot');
					add.push(info.sysroot);
				}

				if (args.indexOf('-target') < 0)
				{
					add.push('-target');
					add.push(triple);
				}

				if (args.indexOf('-mlinker-version') < 0)
				{
					var linkerver = this.call('$triple-ld',['-v']);
					if (linkerver.exit == 0)
					{
						add.push('-mlinker-version=${linkerver.out.trim().split("\n")[0]}');
					}
				}

				add.push('-I');
				add.push(this.clang.clangInclude);
				// var clangLocation = this.call('which',['clang']);
				// if (clangLocation.exit == 0)
				// {
				// 	var location = Path.directory(clangLocation.out.trim());
				// 	var include = '$location/../include/clang';
				// 	if (exists(include))
				// 	{
				// 		var dir = readDirectory(include);
				// 		var path = if (dir.length == 1) {
				// 			dir[0];
				// 		} else {
				// 			var ver = new Clang(this).version;
				// 			if (dir.indexOf(ver) >= 0)
				// 				ver;
				// 			else
				// 				dir.find(function(v2) return Std.parseFloat(v2) == Std.parseFloat(ver));
				// 		}
				// 		add.push('-I');
				// 		add.push('$include/$path/include');
				// 	}
				// }

			case 'ar' | 'as' | 'strip' | 'ranlib'
				| 'checksyms' | 'codesign_allocate' | 'dyldinfo'
				| 'gdb' | 'indr' | 'install_name_tool'
				| 'ld' | 'libtool' | 'lipo' | 'machochecker'
				| 'nm' | 'nmedit' | 'ObjectDump' | 'otool'
				| 'pagestuff' | 'redo_prebinding' | 'seg_addr_table'
				| 'segedit' | 'seg_hack' | 'size' | 'strings' | 'unwinddump':

				cmd = triple+'-'+cmd;
			case _:
				log(args.join(" "));
		}

		var txt = '';
		if (info.name == 'MacOSX' && Sys.getEnv('MACOSX_DEPLOYMENT_TARGET') == null)
		{
			Sys.putEnv('MACOSX_DEPLOYMENT_TARGET',info.ver + '');
			txt = 'MACOSX_DEPLOYMENT_TARGET=${info.ver} ';
		} else if (Sys.getEnv('IPHONEOS_DEPLOYMENT_TARGET') == null) {
			Sys.putEnv('IPHONEOS_DEPLOYMENT_TARGET',info.ver+'');
			txt = 'IPHONEOS_DEPLOYMENT_TARGET=${info.ver} ';
		}
		if (add.length > 0)
			args = args.concat(add);
		log('$txt$cmd ${args.join(" ")}');
		Sys.exit(Sys.command(cmd,args));
	}


	/**
		Sets the Mac/iOs SDK to use.
		@more Examples of valid values are `iphone4.2`, `ios7`, `mac10.8-i386`, `osx10.9-x86_64`, `mingw-i386`
	 **/
	public var sdk:String = null;

	/**
		Lists all currently installed SDKs
		@alias l
	 **/
	public function list()
	{
		for (sdk in getSdks())
			Sys.println(sdk);
	}

	/**
		Prints the prefix where hxcross was installed
	 **/
	public function printPrefix()
	{
		Sys.print( prefix );
	}

	static private function getSdks():Array<String>
	{
		var ret = [];
		if (exists('$prefix/share'))
		{
			for (file in readDirectory('$prefix/share'))
			{
				if (file.endsWith('.sdk'))
				{
					ret.push(file.substr(0,file.length-4));
				}
			}
		}
		ret.sort(Reflect.compare);
		return ret;
	}

	static private function getDefaultVer(name:String):String
	{
		var sdks = getSdks();
		for (sdk in sdks)
		{
			if (sdk.startsWith(name))
			{
				return sdk.substr(name.length);
			}
		}
		return null;
	}

	/**
		Installs one or more sdks with `sdkname` that is currently at `path`.

		@more Will try to auto-detect the format and install it into the correct sdk path.
		      If no `sdkname` is provided, auto-detection will be performed
	 **/
	public function installSdk(path:String, ?sdkname:String)
	{
		// if (!exists(path)) throw 'Path $path does not exist';

		new SdkInstall(this.tools).install(path,sdkname);
	}

	private function sdkInfo(sdk:String):SdkInfo
	{
		var regex = ~/([a-z]+)\-*([0-9\.]*)\-?([^\-]*)/;
		if (!regex.match(sdk.toLowerCase()))
		{
			throw 'Invalid SDK format: $sdk';
		}

		var ver = regex.matched(2);
		if (ver == '')
			ver = null;

		var arch = regex.matched(3);

		var ret = switch(regex.matched(1))
		{
			case 'ios' | 'iphone' | 'iphoneos':
				var archTriple = arch;
				switch (arch)
				{
					case 'x86' | 'sim' | 'i686' | 'i586' | 'i486' | 'i386':
						arch = archTriple = 'i386';
					case _ if (arch == '' || arch == null || arch.startsWith('arm')):
						archTriple = 'arm';
						if (arch == '' || arch == null)
							arch = 'arm';
				}

				if (arch == 'arm')
				{
					arch = 'armv7';
				}

				if (ver == null)
				{
					var env = Sys.getEnv('IPHONEOS_DEPLOYMENT_TARGET');
					if (env != null)
						ver = env;
				}
				{ name:'iPhoneOS', ver:ver, triple:'$archTriple-apple-darwin', arch:arch, sysroot:null };

			case 'iphonesimulator' | 'iphonesim':
				if (ver == null)
				{
					var env = Sys.getEnv('IPHONEOS_DEPLOYMENT_TARGET');
					if (env != null)
						ver = env;
				}
				{ name:'iPhoneSimulator', ver:ver, triple:'i386-apple-darwin', arch:arch, sysroot:null };

			case 'mac' | 'osx' | 'macos' | 'macosx':
				if (arch == null || arch == '')
					arch = 'x86_64';
				switch (arch)
				{
					case 'x86' | 'i686' | 'i586' | 'i486':
						arch = 'i386';
					case 'x64':
						arch = 'x86_64';
					case _:
				}

				if (ver == null)
				{
					var env = Sys.getEnv('MACOSX_DEPLOYMENT_TARGET');
					if (env != null)
						ver = env;
				}
				{ name:'MacOSX', ver:ver, triple:'$arch-apple-darwin', arch:arch, sysroot:null };

			case _:
				throw 'Unrecognized SDK: $sdk . Valid values are: `ios`,`mac` and `windows`';
		}

		if (ret.ver == null)
		{
			ret.ver = getDefaultVer(ret.name);
		}

		ret.sysroot = '$prefix/share/${ret.name}${ret.ver}.sdk';
		if (!exists(ret.sysroot))
		{
			var ver = Std.parseFloat(ret.ver);
			if (Math.isNaN(ver))
			{
				ret.ver = getDefaultVer(ret.name);
			} else {
				var best = null,
					bestVer = Math.POSITIVE_INFINITY;
				for (sdk in getSdks())
				{
					if (sdk.startsWith(ret.name))
					{
						var v = Std.parseFloat(sdk.substr(ret.name.length));
						if (v >= ver && v < bestVer)
						{
							best = sdk.substr(ret.name.length);
							bestVer = v;
						}
					}
				}
				if (best != null)
					ret.sysroot = '$prefix/share/${ret.name}$best.sdk';
			}
		}

		if (!exists(ret.sysroot))
		{
			warn('No installed SDK was found for ${ret.name}! Please install one with `hxcross --install-sdk`');
			Sys.exit(5);
		}

		// check triple
		var v = ret.ver.split('.');
		var darwinVer = switch [ ret.name, Std.parseInt(v[0]), v[1] == null ? 0 : Std.parseInt(v[1]) ] {
			case ['MacOSX', 10, ver] if (ver <= 7):
				11;
			case ['MacOSX', 10, 8]:
				12;
			case ['MacOSX', 10, 9]:
				13;
			case ['MacOSX', 10, _]:
				14;
			case ['iPhoneOS', ver, _] if (ver <= 5):
				11;
			case ['iPhoneOS', 6, _]:
				13;
			case ['iPhoneOS', _, _]:
				14;
			case _:
				14;
		};
		var found = false;
		for (val in [darwinVer+'',''])
		{
			if (this.cbool('which',[ret.triple+val+'-ar']))
			{
				ret.triple = ret.triple + val;
				found = true;
				break;
			}
		}

		if (!found)
		{
			errln('Cannot find a valid binutils toolchain for ${ret.triple}. Please install it before using hxcross with this target');
			Sys.exit(4);
		}

		return ret;
	}

	@:isVar public static var prefix(get,null):String = Sys.getEnv("HXCROSS_PREFIX");

	private static function get_prefix():String
	{
		if (prefix == null)
		{
			prefix = haxe.macro.Compiler.getDefine('HXCROSS_PREFIX');
			if (prefix == '' || prefix == '1')
				prefix = null;
		}

		if (prefix == null)
		{
			var exec = Sys.executablePath();
			var regex = ~/\/bin\/[^\/]+$/;
			if (!regex.match(exec))
			{
				throw 'Cannot determine installation prefix by the executable name (${Sys.executablePath()}). Please use the HXCROSS_PREFIX environment variable';
			}
			prefix = regex.matchedLeft();
		}
		return prefix;
	}
}
