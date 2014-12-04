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

	private var curTmp:Null<String>;

	@:skip public var tools(default,null):Tools;
	@:skip public var clang(default,null):apps.Clang;

	public function new()
	{
		super();
		this.tools = new Tools(this);
		this.clang = new apps.Clang(this);
	}

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
		if (!quiet) Sys.stderr().writeString('ERR: $v\n');
	}

	@:skip public function errlog(v:Dynamic)
	{
		if (verbose) Sys.stderr().writeString('ERRLOG: $v\n');
	}

	@:skip public function msg(v:Dynamic)
	{
		if (!quiet) Sys.println(v);
	}

	@:skip public function echoCall(cmd:String, args:Array<String>):Int
	{
		this.msg('$cmd ${args.join(" ")}');
		if (quiet)
			return call(cmd,args).exit;
		else
			return Sys.command(cmd,args);
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
		var ended = new Lock();
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
			ended.release();
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
		ended.wait();
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
		var tmpdir = curTmp == null ? Sys.getEnv("TMPDIR") : curTmp;
		var ret = null;
		// first option
		var cmd = if (tmpdir == null)
			{
				call('mktemp',['-d']);
			} else {
				call('mktemp',['-d','--tmpdir=$tmpdir']);
			};
		if (cmd.exit == 0)
		{
			ret = cmd.out.trim();
		} else {
			if (tmpdir == null)
				tmpdir = Sys.getEnv("TMP");
			if (tmpdir == null)
				tmpdir = Sys.getEnv("TEMP");
			if (tmpdir == null)
				tmpdir = '/tmp';

			do
			{
				ret = '$tmpdir/tmpf${Std.random(10000)}_${Std.random(10000)}';
			} while(exists(ret));

			createDirectory(ret);
		}

		if (this.curTmp == null)
		{
			this.curTmp = ret;
			return this.tmpdir();
		} else {
			return ret;
		}
	}

}
