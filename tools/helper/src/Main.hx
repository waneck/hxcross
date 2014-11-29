/**
	Helper to install and run cross-compilers from Haxe.
 **/
class Main extends mcli.CommandLine
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
		Sets the Mac/iOs SDK to use. Examples of valid values are `iphone4.2`, `ios7`, `mac10.8`
	 **/
	public var sdk:String = "ios";

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
		Adds a sdk with `sdkname` that is currently at `path`.
	 **/
	public function addSdk(sdkname:String, path:String)
	{
	}

	/**
	 **/
	public function run(d:mcli.Dispatch)
	{
		var args = d.args.splice(0,d.args.length);
		switch (args[0])
		{
			case null:
				Sys.stderr().writeString('x-hxcpp run: Missing argument');
				Sys.exit(3);
			case 'clang' | 'clang++':
			case 'ar' | 'strip' | 'ranlib':
				var arg = args.shift();
				arg = getPrefix() + '-' + arg;
				Sys.exit(Sys.command(arg,args));
		}
	}

	private function getPrefix()
	{
		var regex = ~/$(\w+)([0-9\.]*)/;
		if (!regex.match(sdk))
		{
			throw 'Invalid SDK format: $sdk';
		}
		switch(regex.matched(1))
		{
			case 'ios':
		}
	}
}
