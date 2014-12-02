import sys.io.Process;
import sys.FileSystem.*;

#if cpp
import cpp.vm.*;
#elseif neko
import neko.vm.*;
#end

using StringTools;

class Cli extends mcli.CommandLine
{
	/**
		Defaults any interactive question to `yes`
		@alias y
	 **/
	public var yes:Bool;

	/**
		Forces any interactive question to be as default
		@alias f
	 **/
	public var force:Bool;

	/**
		Enhances the verbosity level
		@alias v
	 **/
	public var verbose:Bool;

	/**
		Diminishes the verbosity level
		@alias q
	 **/
	public var quiet:Bool;

	@:skip public function ask(txt:String, ?defaultOption:Bool):Bool
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

	@:skip public function log(v:Dynamic)
	{
		if (verbose) Sys.println(v);
	}

	@:skip public function warn(v:Dynamic)
	{
		if (!quiet) Sys.stderr().writeString('WARNING: $v\n');
	}

	@:skip public function errln(v:Dynamic)
	{
		if (!quiet) Sys.stderr().writeString('$v\n');
	}

	@:skip public function errlog(v:Dynamic)
	{
		if (verbose) Sys.stderr().writeString('$v\n');
	}

	@:skip public function msg(v:Dynamic)
	{
		if (!quiet) Sys.println(v);
	}

	@:skip public function call(cmd:String, args:Array<String>):{ out:String, exit:Int }
	{
		log('-> CALL ' + cmd + ' ' + args.join(' '));

		var out = new StringBuf();
		var proc = new Process(cmd,args);
		var writing = new Lock();
		writing.release();
		inline function write(str:String):Bool
		{
			if (!writing.wait())
			{
				trace('kill');
				proc.kill();
				return false;
			} else {
				out.add(str);
				out.addChar('\n'.code);
				writing.release();
				return true;
			}
		}

		proc.stderr.close();
		var stderr = Thread.create(function() {
			var input = proc.stderr;
			try
			{
				while(true)
				{
					var ln = input.readLine();
					log(ln);
					if (!write(ln))
						break;
				}
			}
			catch(e:haxe.io.Eof) {}
		});

		var input = proc.stdout;
		try
		{
			while(true)
			{
				var ln = input.readLine();
				log(ln);
				if (!write(ln))
					break;
			}
		}
		catch(e:haxe.io.Eof) {}

		var id = proc.exitCode();
		var localOut = new StringBuf();

		try { proc.stdout.close(); } catch(e:Dynamic) {}
		try { proc.stderr.close(); } catch(e:Dynamic) {}
		try { proc.close(); } catch(e:Dynamic) {}

		log('<- Process `$cmd` exited with code $id');
		return { out:out.toString(), exit: id };
	}

	@:skip public function cbool(cmd:String, args:Array<String>):Bool
	{
		return call(cmd,args).exit == 0;
	}

	@:skip public function tmpdir()
	{
		// first option
		var ret = call('mktemp',['-d']);
		if (ret.exit == 0)
		{
			return ret.out.trim();
		}
		var dirname = Sys.getEnv("TMP");
		if (dirname == null)
			dirname = Sys.getEnv("TEMP");
		if (dirname == null)
			dirname = '/tmp';

		var ret = null;
		do
		{
			ret = '$dirname/tmpf${Std.random(10000)}_${Std.random(10000)}';
		} while(exists(ret));

		createDirectory(ret);
		return ret;
	}
}
