import sys.FileSystem.*;

@:access(Cli)
class Install extends mcli.CommandLine
{
	private var cli:Cli;
	public function new(cli)
	{
		super();
		this.cli = cli;
	}

	/**
		Installs an ios toolchain based on clang
	 **/
	public function iosToolchain()
	{
		prepareDarwinToolchain();
		installDarwinToolchain('arm');
	}

	/**
		Installs a mac toolchain based on clang
	 **/
	public function macToolchain()
	{
		prepareDarwinToolchain();
		if (cli.ask('Install i386 architecture?',true))
			installDarwinToolchain('i386');
		if (cli.ask('Install x86_64 architecture?',true))
			installDarwinToolchain('x86_64');
		if (cli.ask('Install x86_64h architecture?',true))
			installDarwinToolchain('x86_64h');
	}

	private function prepareDarwinToolchain()
	{
		switch (cli.tools.packman.cmd)
		{
			case 'apt-get' | 'pacman':
				cli.tools.install('toolchain dependencies', [
					'apt-get' => ["gcc", "g++", "clang", "libclang-dev", "uuid-dev", "libssl-dev", "libpng12-dev", "libicu-dev", "bison", "flex", "libsqlite3-dev", "libtool", "llvm-dev", "libxml2-dev", "automake", "pkg-config"],
					'pacman' => ["gcc", "extra/clang", "core/libutil-linux", "core/openssl", "extra/libpng", "icu", "bison", "flex", "libtool", "sqlite3", "llvm", "xml2", "pkg-config", "automake"],
				]);
			case _:
				if (!cli.ask('The following packages are needed in order to install this toolchain on your system:\nclang 3.2+, llvm-dev, libxml2-dev, uuid-dev, openssl-dev. Be sure you have them installed before continuing. Continue?',true))
				{
					cli.msg('Aborted');
					Sys.exit(3);
				}
		}

		var tools = cli.tools;
		tools.checkExec('clang',['default' => ['clang'], 'yum' => ['llvm-clang']]);
		tools.checkExec('git',['default' => ['git']]);

		var clangVer = cli.clang.version;
		if (clangVer == null)
		{
			cli.warn('No clang version was detected! This installation may fail');
		} else if (Std.parseFloat(clangVer) < 3.2) {
			cli.warn('Your clang version ($clangVer) is too old. This installation may fail');
		}
	}

	private function installDarwinToolchain(arch:String)
	{
		if (!_installDarwinToolchain(arch))
		{
			cli.warn('Install did not succeed');
			Sys.exit(6);
		}
	}

	private function _installDarwinToolchain(arch:String)
	{
		var tmp = cli.tmpdir();
		if (!cli.cbool('git',['clone','--recursive','--depth=10','https://github.com/waneck/linux-ios-toolchain.git','$tmp/ios-toolchain']))
			return false;
		var old = Sys.getCwd();
		Sys.setCwd('$tmp/ios-toolchain');
		var prefix =
			// unfortunately clang only searchs for toolchains in the same prefix as it was installed itself
			// so we must configure it to be the same
			cli.clang.prefix;

		cli.msg('cd $tmp/ios-toolchain');
		var success =
			cli.cbool('./configure',['$arch-apple-darwin'],true) &&
			cli.cbool('make',['PREFIX=$prefix'],true) &&
			cli.cbool('sudo',['make','install'],true);
		Sys.setCwd(old);

		cli.cbool('rm',['-rf',tmp]);
		return success;
	}
}
