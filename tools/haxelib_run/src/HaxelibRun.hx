import sys.FileSystem.*;
/**

.	██╗  ██╗██╗  ██╗ ██████╗██████╗  ██████╗ ███████╗███████╗
.	██║  ██║╚██╗██╔╝██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔════╝
.	███████║ ╚███╔╝ ██║     ██████╔╝██║   ██║███████╗███████╗
.	██╔══██║ ██╔██╗ ██║     ██╔══██╗██║   ██║╚════██║╚════██║
.	██║  ██║██╔╝ ██╗╚██████╗██║  ██║╚██████╔╝███████║███████║
.	╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝

	This tool will compile and properly setup the `hxcross` helper into your path.
 **/
class HaxelibRun extends mcli.CommandLine
{
	static function main()
	{
		var args = Sys.args();
		var callPath = null;
		if (Sys.getEnv("HAXELIB_RUN") != null)
			callPath = args.pop();

		new mcli.Dispatch(args).dispatch(new HaxelibRun(callPath));
	}

	private var callPath:Null<String>;
	public function new(callPath)
	{
		super();
		this.callPath = callPath;
	}

	/**
		Sets the prefix where to install the tool. Defaults to `/usr`
	 **/
	public var prefix:String = '/usr';

	/**
		Setups the hxcross command-line tool into path. After setup is complete, the `hxcross` command-line tool will be available
	 **/
	public function setup(d:mcli.Dispatch)
	{
		if (d.args.length != 0) throw '`setup` takes no arguments, but some were used: ${d.args.join(" ")}';

		// compile hxcross
		Sys.setCwd(Sys.getCwd()+'tools/helper');
		var res = Sys.command('haxe',['build.hxml','-D','HXCROSS_PREFIX=$prefix']);
		if (res != 0) Sys.exit(res);

		// install hxcross
		var needsSudo = false;
		var root = prefix;
		while (!exists(root))
		{
			root = haxe.io.Path.directory(root);
		}
		if (root == '' || root == '.') throw 'Invalid prefix directory!';

		needsSudo = stat(root).uid == 0;

		var ret = false;
		if (needsSudo)
		{
			ret = Sys.command('sudo',['mkdir','-p','$prefix/bin']) == 0 &&
				Sys.command('sudo',['cp','bin/Main-debug','$prefix/bin/hxcross']) == 0;
		} else {
			ret = Sys.command('mkdir',['-p','$prefix/bin']) == 0 &&
				Sys.command('cp',['bin/Main-debug','$prefix/bin/hxcross']) == 0;
		}
		if (!ret)
		{
			Sys.stderr().writeString('Setup failed\n');
			Sys.exit(1);
		}
		Sys.println("Setup complete!");
	}
}
