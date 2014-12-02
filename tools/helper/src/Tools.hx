import sys.FileSystem.*;

class Tools
{
	public var cli(default,null):Cli;

	public function new(cli)
	{
		this.cli = cli;
	}

	public function clangVersion():Null<Float>
	{
		var regex = ~/clang version (\d+)\.(\d+)/;
		var proc = cli.call('clang',['-v']);
		if (regex.match(proc.out))
			return Std.parseFloat(regex.matched(1) + "." + regex.matched(2));
		return null;
	}

	public function install(name:String, packNames:Map<String,Array<String>>)
	{
		var ret = null;
		if (packNames != null)
		{
			cli.msg('The library $name is not installed. hxcross will try to install it automatically. Please follow the instructions if needed');
			if (exists('/etc/debian_version')) //apt-get
			{
				var libs = packNames['apt-get'];
				if (libs == null) libs = packNames['default'];
				if (libs != null) ret = cli.call('sudo',['apt-get','install','-y'].concat(libs));
			} else if (exists('/etc/redhat-release')) { //yum
				var libs = packNames['yum'];
				if (libs == null) libs = packNames['default'];
				if (libs != null) ret = cli.call('sudo',['yum','install'].concat(libs));
			} else if (exists('/etc/arch-release')) { //pacman
				var libs = packNames['pacman'];
				if (libs == null) libs = packNames['default'];
				if (libs != null) ret = cli.call('sudo',['pacman','-S'].concat(libs));
			} else if (exists('/etc/gentoo-release')) { //emerge
				var libs = packNames['emerge'];
				if (libs == null) libs = packNames['default'];
				if (libs != null) ret = cli.call('sudo',['emerge'].concat(libs));
			} else if (exists('/etc/SuSE-release')) { //zypp
				var libs = packNames['zypp'];
				if (libs == null) libs = packNames['default'];
				if (libs != null) ret = cli.call('sudo',['zypper','install'].concat(libs));
			} else {
				// check for apt-get anyway
				var libs = packNames['apt-get'];
				if (libs == null) libs = packNames['default'];
				if (libs != null) ret = cli.call('sudo',['apt-get','install','-y'].concat(libs));
			}
		}
		if (ret != null && ret.exit == 0)
			return;

		cli.warn("The application/library " + name + " is not installed. Additionally, hxcross couldn't install the application automatically. Please install it first and continue");
		if (!cli.ask('Continue?',false))
			Sys.exit(1);
	}


	public function checkExec(name:String, ?packs:Map<String,Array<String>>)
	{
		var exists = cli.call('which',[name]);
		if (exists.exit != 0)
		{
			install(name, packs);
		}
	}

	public function mountDmg(path:String, into:String):Null<String>
	{
		if (!exists(into)) createDirectory(into);

		checkExec('7z', [ 'default' => ['p7zip'], 'yum' => ['7zip'] ]);
		var res = cli.call('7z',['l',path]);
		if (res.exit != 0) { cli.warn('$path is not a valid dmg file'); return null; }
		var regex = ~/(\d+)\.hfs/;
		if (!regex.match(res.out)) { cli.warn('$path is of unexpected dmg format'); return null; }

		cli.msg('mounting $path ...');
		var tmp = cli.tmpdir();
		var file = regex.matched(1)+'.hfs';

		var success =
			cli.cbool('7z',['-o$tmp','x',path,file]) &&
			cli.cbool('sudo',['modprobe','hfsplus']) &&
			cli.cbool('sudo',['mount', '-t', 'hfsplus', '-o', 'loop', '$tmp/$file', into]);

		if (!success)
			return null;
		else
			return '$tmp/$file';
	}

	public function unmountDmg(handle:String,path:String):Bool
	{
		if (!cli.cbool('sudo',['umount','-fl',path]))
			return false;
		deleteFile(handle);
		return true;
	}
}
