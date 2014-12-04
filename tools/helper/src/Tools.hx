import sys.FileSystem.*;
import haxe.io.Path;

class Tools
{
	public var cli(default,null):Cli;

	public function new(cli)
	{
		this.cli = cli;
	}

	public function clangVersion():Null<String>
	{
		var regex = ~/clang version (\d+)\.(\d+)/;
		var proc = cli.call('clang',['-v']);
		if (regex.match(proc.out))
			return regex.matched(1) + "." + regex.matched(2);
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
		var exists = which(name);
		if (packs == null)
			packs = [ 'default' => [name] ];
		if (exists.exit != 0)
		{
			install(name, packs);
		}
	}

	public function checkLib(header:String,?packs:Map<String,Array<String>>)
	{
	}

	public function which(name:String)
	{
		return cli.call('which',[name]);
	}

	private function installDarling():Bool
	{
		checkExec('git'); checkExec('cmake');
		checkExec('fusermount',[ 'default' => ['fuse'] ]);
		checkLib('fuse.h',['apt-get' => ['libfuse-dev'] ]);
		var tmp = cli.tmpdir();
		var cdir = Sys.getCwd();
		Sys.setCwd(tmp);
		var s = cli.echoCall('git',['clone','https://github.com/LubosD/darling-dmg','darling-dmg']) == 0;
		if (s)
			Sys.setCwd('$tmp/darling-dmg');
		var s = s &&
			cli.echoCall('cmake',['-DCMAKE_INSTALL_PREFIX=${Main.prefix}']) == 0 &&
			cli.echoCall('make',[]) == 0 &&
			( stat(Main.prefix).uid == 0 ?
				cli.echoCall('sudo', ['make','install']) == 0 :
				cli.echoCall('make',['install']) == 0 );
		cli.call('rm',['-rf',tmp]);
		Sys.setCwd(cdir);
		return s;
	}

	public function mountDmg(path:String, into:String):Null<String>
	{
		if (!exists(into)) createDirectory(into);
		var useDarling = which('darling-dmg').exit == 0;
		if (!useDarling)
		{
			if (cli.ask('The application `darling-dmg` was not found. '+
						'We can try to proceed without it, but the other solutions are buggy and may not work on all DMGs.\n'+
						'You can download and install it at https://github.com/LubosD/darling-dmg or you can choose to try to automatically install it. Do you wish to install it automatically?'))
			{
				if (installDarling())
					useDarling = true;
				else
					cli.msg('Installation failed. Falling back to method without it');
			}
		}

		if (useDarling)
		{
			var success = (stat(Main.prefix).uid == 0 ?
					Sys.command("/bin/sh",['-c','sudo darling-dmg "$path" "$into" -o allow_other > /dev/null']) :
					Sys.command("/bin/sh",['-c','darling-dmg "$path" "$into" > /dev/null'])
					) == 0;
			if (success)
				return 'darling';
			else
				return null;
		} else {
			checkExec('7z', [ 'default' => ['p7zip'], 'yum' => ['7zip'] ]);
			var res = cli.call('7z',['l',path]);
			if (res.exit != 0) { cli.warn('$path is not a valid dmg file'); return null; }
			var regex = ~/(\d+)\.hfs/;
			if (!regex.match(res.out)) { cli.warn('$path is of unexpected dmg format'); return null; }

			cli.msg('mounting $path ...');
			var tmp = Path.directory(path);
			if (tmp == '')
				tmp = './';

			var file = regex.matched(1)+'.hfs';

			var success =
				cli.cbool('7z',['-o$tmp','-y','x',path,file]) &&
				cli.cbool('sudo',['modprobe','hfsplus']) &&
				cli.cbool('sudo',['mount', '-t', 'hfsplus', '-o', 'loop', '$tmp/$file', into]);

			if (!success)
				return null;
			else
				return '$tmp/$file';
		}
	}

	public function unmountDmg(handle:String,path:String):Bool
	{
		if (handle == 'darling' && stat(Main.prefix).uid != 0)
		{
			return cli.cbool('fusermount',['-uz',path]);
		} else {
			if (!cli.cbool('sudo',['umount','-fl',path]))
				return false;
			if (handle != 'darling')
				deleteFile(handle);
			return true;
		}
	}
}
