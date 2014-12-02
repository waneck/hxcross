@:access(Cli)
class Install extends mcli.CommandLine
{
	private var cli:Cli;
	private var tools:Tools;
	public function new(cli, tools)
	{
		super();
		this.cli = cli;
		this.tools = tools;
	}

	/**
		Installs an ios toolchain based on clang
	 **/
	public function iosToolchain()
	{
		if (!cli.ask('The following packages are needed in order to install this toolchain on your system:\nclang 3.2+, llvm-dev, libxml2-dev, uuid-dev, openssl-dev. Be sure you have them installed before continuing. Continue?',true))
		{
			cli.msg('Aborted');
			Sys.exit(3);
		}

		var clangVer = tools.clangVersion();
		if (clangVer == null)
		{
			cli.warn('No clang version was detected! This installation may fail');
		} else if (clangVer < 3.2) {
			cli.warn('Your clang version ($clangVer) is too old. This installation may fail');
		}
	}
}
