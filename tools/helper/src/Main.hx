import hxcpp.StaticStd;
import hxcpp.StaticZlib;
import hxcpp.StaticRegexp;

using StringTools;
/**
	Helper to install and run cross-compilers from Haxe.
 **/
class Main extends Cli
{
	static function main()
	{
		var args = Sys.args();
		var callPath = null;
		if (Sys.getEnv("HAXELIB_RUN") != null)
			callPath = args.pop();

		new mcli.Dispatch(args).dispatch(new Main(callPath));
	}

	private var callPath:Null<String>;
	public function new(callPath)
	{
		super();
		this.callPath = callPath;
	}

	/**
		Builds and installs a specific cross-compiler. Run `hxcross install --help` to see all options
	 **/
	public function install(d:mcli.Dispatch)
	{
		// check
		// clone repo ( https://github.com/tpoechtrager/cctools-port )
		//
	}

	/**
		Runs a command using the sdk specified
	 **/
	public function run(d:mcli.Dispatch)
	{
		var info = sdkInfo(sdk),
			triple = info.triple;
		var args = d.args.splice(0,d.args.length);
		args.reverse();
		switch (args[0])
		{
			case null:
				Sys.stderr().writeString('hxcross run: Missing argument\n');
				Sys.exit(3);
			case 'clang' | 'clang++':
				// check arguments:
				// add isysroot if needed
				// add -arch if needed
				// if more than one sdk, compile as many times as needed
			case 'ar' | 'as' | 'strip' | 'ranlib'
				| 'checksyms' | 'codesign_allocate' | 'dyldinfo'
				| 'gdb' | 'indr' | 'install_name_tool'
				| 'ld' | 'libtool' | 'lipo' | 'machochecker'
				| 'nm' | 'nmedit' | 'ObjectDump' | 'otool'
				| 'pagestuff' | 'redo_prebinding' | 'seg_addr_table'
				| 'segedit' | 'seg_hack' | 'size' | 'strings' | 'unwinddump':

				Sys.exit(Sys.command(triple + args.shift(),args));
			case _:
				Sys.exit(Sys.command(args.shift(),args));
		}
	}


	/**
		Sets the Mac/iOs SDK to use.
		Examples of valid values are `iphone4.2`, `ios7`, `mac10.8-i386`, `osx10.9-x86_64`, `mingw-i386`
	 **/
	public var sdk:String = "ios";

	/**
		Lists all currently installed SDKs
		@alias l
	 **/
	public function list()
	{
	}

	/**
		Installs a sdk with `sdkname` that is currently at `path`. Will try to auto-detect the format and install it into the correct sdk path.
		If no `sdkname` is provided, auto-dectetion will be performed
	 **/
	public function installSdk(path:String, ?sdkname:String)
	{
	}

	private static function sdkInfo(sdk:String):SdkInfo
	{
		var regex = ~/([a-z]+)\-*([0-9\.]*)\-?([^\-]*)/;
		if (!regex.match(sdk.toLowerCase()))
		{
			throw 'Invalid SDK format: $sdk';
		}

		var ver = regex.matched(2);
		var ver = if (ver == '' || ver == null)
			4.2;
		else
			Std.parseFloat(ver);

		var arch = regex.matched(3);

		switch(regex.matched(1))
		{
			case 'ios' | 'iphone' | 'iphoneos':
				switch (arch)
				{
					case 'x86' | 'sim' | 'i686' | 'i586' | 'i486' | 'i386':
						arch = 'i386';
					case _ if (arch == '' || arch == null || arch.startsWith('arm')):
						arch = 'arm';
				}
				return { name:'ios', ver:ver, triple:'$arch-apple-darwin11-', arch:arch };

			case 'mac' | 'osx':
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
				return { name:'mac', ver:ver, triple:'$arch-apple-darwin11-', arch:arch };

			case _:
				throw 'Unrecognized SDK: $sdk . Valid values are: `ios`,`mac` and `windows`';
		}
		return null;
	}

	@:isVar private static var prefix(get,null):String = Sys.getEnv("HXCROSS_PREFIX");

	private static function get_prefix():String
	{
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
