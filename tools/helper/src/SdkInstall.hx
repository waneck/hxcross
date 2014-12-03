import sys.FileSystem.*;

using StringTools;


class SdkInstall
{
	var tools:Tools;
	var cli:Cli;

	public function new(tools)
	{
		this.tools = tools;
		this.cli = tools.cli;
	}

	public function install(path:String,?sdkname:String)
	{
		if (isDirectory(path))
		{
			handleDir(path,sdkname);
		} else if (path.endsWith('.dmg')) {
			var dmgto = cli.tmpdir();
			var hnd = tools.mountDmg(path, dmgto);
			if (hnd == null) { cli.errln('Mounting $path failed. Exiting'); Sys.exit(1); }
			handleDir(dmgto,sdkname);
			if (!tools.unmountDmg(hnd,dmgto)) cli.warn('Cannot unmount DMG at $dmgto');
		}
	}

	private function handleDir(path:String,sdkname:String)
	{
		if (path.endsWith('.sdk'))
		{
			addSdk(path,sdkname != null ? sdkname : haxe.io.Path.withoutDirectory(path), false);
		}

		var regex = ~/Xcode[^\.]*\.app/;
		for (d in readDirectory(path))
		{
			if (regex.match(d))
			{
				///mnt/Xcode-Beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk/
				var platf = '$path/$d/Contents/Developer/Platforms';
				trace(exists(platf));
				if (exists(platf)) for (platform in readDirectory(platf))
				{
					var platf = '$platf/$platform';
					var sdks = [],
							links = [];
					var dir = fullPath('$platf/Developer/SDKs');
					if (exists('$platf/Developer/SDKs')) for (sdk in readDirectory('$platf/Developer/SDKs'))
					{
						if (fullPath('$dir/$sdk') != '$dir/$sdk')
						{
							links.push(sdk);
							continue;
						}
						if (isDirectory('$dir/$sdk') && sdk.endsWith('.sdk'))
						{
							sdks.push(sdk);
						}
					}
					if (links.length == 1 && sdks.length == 1)
					{
						addSdk('$dir/${sdks[0]}',links[0],true);
					} else {
						for (sdk in sdks)
							addSdk('$dir/$sdk',sdk,true);
					}
				}
			}
		}
	}

	private function addSdk(path:String,name:String,ask:Bool)
	{
		if (ask && !cli.ask('Install SDK $name?',true))
			return true;
		var prefix = Main.prefix;
		var needsSudo = stat(prefix).uid == 0;
		inline function call(cmd,args):Bool
		{
			return if (needsSudo)
				cli.cbool('sudo',[cmd].concat(args));
			else
				cli.cbool(cmd,args);
		}

		var dir = '$prefix/share';
		if (!exists(dir))
			call('mkdir',['-p','$prefix/share']) || return false;

		if (exists('$prefix/share/$name'))
			if (cli.ask('"$prefix/share/$name" already exists. Replace?'))
				call('rm',['-rf','$prefix/share/$name']) || return false;
			else
				return true;

		call('cp',['-rf','$path','$prefix/share/$name']) || return false;
		cli.log('Succesfully installed SDK $name');
		return true;
	}
}
