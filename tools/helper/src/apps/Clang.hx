package apps;
import sys.FileSystem.*;
using StringTools;
using Lambda;

class Clang
{
	private var cli:Cli;
	@:isVar public var searchPaths(get,null):{ programs:Array<String>, libraries:Array<String> };
	@:isVar public var version(get,null):String;
	@:isVar public var path(get,null):String;
	@:isVar public var clangIncludes(get,null):Array<String>;
	@:isVar public var includes(get,null):Array<String>;
	@:isVar public var prefix(get,null):String;

	@:isVar private var driverArgs(get,null):Array<String>;

	public function new(cli)
	{
		this.cli = cli;
	}

	private function get_prefix():String
	{
		return haxe.io.Path.directory(path) + '/..';
	}

	private function get_clangIncludes()
	{
		if (clangIncludes == null)
		{
			var ret = clangIncludes = [];
			for (i in includes)
			{
				var args = driverArgs;
				for (i in 0...args.length)
				{
					if (args[i] == '-internal-isystem')
					{
						if ( exists(args[i+1] + '/stdarg.h') )
							ret.push(args[i+1]);
					}
				}
			}
		}
		return clangIncludes;
	}

	private function get_includes()
	{
		if (includes == null)
		{
			var ret = [];
			var args = driverArgs;
			for (i in 0...args.length)
			{
				if (args[i].endsWith('isystem'))
					ret.push(args[i+1]);
			}
			includes = ret;
		}
		return includes;
	}

	private function getArg(name:String)
	{
		var args = driverArgs;
		for (i in 0...args.length)
		{
			if (args[i] == name)
				return args[i+1];
		}
		return null;
	}

	private function getArgs(name:String)
	{
		var ret = [];
		var args = driverArgs;
		for (i in 0...args.length)
		{
			if (args[i] == name)
				ret.push(args[i+1]);
		}
		return ret;
	}

	private function get_driverArgs()
	{
		if (driverArgs != null)
			return driverArgs;

		var tmp = cli.tmpdir() + '/dummy.cpp';
		sys.io.File.saveContent(tmp,'');
		var out = cli.call('clang',['-###','-fsyntax-only','-c',tmp]);
		if (out.exit != 0)
		{
			cli.errlog('clang -### failed. Trying to infer some clang paths');
			var location = haxe.io.Path.directory(this.path);
			var include = '$location/../include/clang';
			if (!exists(include)) include = '/usr/include/clang';
			if (exists(include))
			{
				var dir = readDirectory(include);
				var path = if (dir.length == 1) {
					dir[0];
				} else {
					var ver = this.version;
					if (dir.indexOf(ver) >= 0)
						ver;
					else
						dir.find(function(v2) return Std.parseFloat(v2) == Std.parseFloat(ver));
				}
				driverArgs = ['-resource-dir','$include/$path','-internal-isystem','/usr/include'];
			} else {
				driverArgs = ['-resource-dir','/usr/include','-internal-isystem','/usr/include'];
			}
		} else {
			var out = out.out.trim().split('\n').pop();
			var args = [], inEscape = false, inQuote = false;
			var chr = -1, i = 0;
			var buf = new StringBuf();
			while ( !StringTools.isEof(chr = StringTools.fastCodeAt(out,i++)) )
			{
				switch(chr)
				{
					case '"'.code:
						if (inEscape)
							buf.addChar('"'.code);
						else if (inQuote)
							inQuote = false;
						else
							inQuote = true;
					case '\\'.code if (inQuote && !inEscape):
						inEscape = true;
						continue;
					case ' '.code if (!inQuote):
						var c = buf.toString();
						if (c.length > 0)
						{
							args.push(c);
							buf = new StringBuf();
						}
					case _:
						buf.addChar(chr);
				}
				inEscape = false;
			}
			var c = buf.toString();
			if (c.length > 0)
				args.push(buf.toString());
			driverArgs = args;
		}
		return driverArgs;
	}

	private function get_searchPaths()
	{
		if (searchPaths == null)
		{
			var ret = cli.call('clang',['-print-search-dirs']);
			//programs: =/usr/bin:/usr/bin/../lib/gcc/x86_64-linux-gnu/4.8/../../../../x86_64-linux-gnu/bin
			//libraries: =/usr/bin/../lib/clang/3.2:/usr/bin/../lib/gcc/x86_64-linux-gnu/4.8:/usr/bin/../lib/gcc/x86_64-linux-gnu/4.8/../../../x86_64-linux-gnu:/lib/x86_64-linux-gnu:/lib/../lib64:/usr/lib/x86_64-linux-gnu:/usr/bin/../lib/gcc/x86_64-linux-gnu/4.8/../../..:/lib:/usr/lib
			var sp:Dynamic = {};
			for (line in ret.out.split('\n'))
			{
				var spl = line.split(':');
				var name = spl.shift();
				spl[0] = spl[0].trim();
				if (spl[0].startsWith('='))
					spl[0] = spl[0].substr(1);
				Reflect.setField(sp,name,spl);
			}

			if (ret.exit != 0 || sp.programs == null || sp.libraries == null)
			{
				cli.warn('clang -print-search-dirs returned unparseable output');
				searchPaths = { programs:['/usr/bin'], libraries:['/usr/lib'] };
			} else {
				searchPaths = sp;
			}
		}
		return searchPaths;
	}

	private function get_version()
	{
		if (version == null)
		{
			var regex = ~/clang version (\d+)\.(\d+)(\.\d+)*/;
			var proc = cli.call('clang',['-v']);
			if (regex.match(proc.out))
				version = regex.matched(0);
			else
				throw "cannot determine clang version: ${proc.out}";
		}
		return version;
	}

	private function get_path()
	{
		if (path == null)
		{
			var w = cli.call('which',['clang']);
			if (w.exit == 0)
				path = w.out.trim();
			else
				throw 'clang not found in path!';
		}
		return path;
	}

}
