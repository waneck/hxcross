using StringTools;

class Cli extends mcli.CommandLine
{
	/**
		Defaults any interactive question to `yes`
		@alias y
	 **/
	public var yes:Bool;

	/**
		Forces any interactive question to be answered by its default answer
		@alias f
	 **/
	public var force:Bool;

	/**
		Enhances the verbosity level of the application
		@alias v
	 **/
	public var verbose:Bool;

	/**
		Diminishes the verbosity level of the application
		@alias q
	 **/
	public var quiet:Bool;

	private function ask(txt:String, ?defaultOption:Bool):Bool
	{
		if (yes) return true;
		if ( !(quiet && force && defaultOption != null) )
			Sys.println(txt);
		if (defaultOption != null && force) return defaultOption;

		var res:Null<Bool> = null;
		do {
			var y = defaultOption == true ? "Y" : "y",
				n = defaultOption == false ? "N" : "n";
			Sys.print('($y/$n) ');
			var ln = Sys.stdin().readLine().trim();
			if (ln == '')
				res = defaultOption;
			else switch (ln.toLowerCase()) {
				case 'y':
					return true;
				case 'n':
					return false;
			}
		} while( res == null );
		return res;
	}

	private function log(v:Dynamic)
	{
		if (verbose) Sys.println(v);
	}

	private function msg(v:Dynamic)
	{
		if (!quiet) Sys.println(v);
	}
}
