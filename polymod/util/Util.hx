/**
 * Copyright (c) 2018 Level Up Labs, LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

package polymod.util;

import polymod.Polymod;
import polymod.fs.IFileSystem;
import polymod.Polymod.PolymodError;
import polymod.Polymod.PolymodErrorType;
import polymod.util.CSV.CSVParseFormat;

#if unifill
import unifill.Unifill;
#end

import haxe.Utf8;

typedef MergeRules =
{
	?csv:CSVParseFormat
}

class Util
{
	public static var fileSystem:IFileSystem = null;

	public static function mergeAndAppendText(baseText:String, id:String, dirs:Array<String>, getModText:String->String->String, mergeRules:MergeRules=null):String
	{
		var text = baseText;

		for (d in dirs)
		{
			if (hasMerge(id, d))
			{
				text = mergeText(text, id, d, getModText, mergeRules);
				text = mergeText(text, id, d, getModText, mergeRules);
			}
			if (hasAppend(id, d))
			{
				text = appendText(text, id, d, getModText);
			}
		}

		return text;
	}

	/**
	 * Looks for a "_merge" entry for an asset and tries to merge its contents into the original
	 * With the following rules:
	 * - Only applies to XML, TSV, and CSV files (identified by extension)
	 * - Adds single nodes from the merged asset into the original
	 * - If the original has that node too, it overwrites the original information
	 * @param	baseText	the basic text file you're merging extra content into
	 * @param	id	the name of the asset file
	 * @param	getModText	a function for getting the mod's contribution
	 * @param	mergeRules	formatting rules to help with merging
	 * @return
	 */

	public static function mergeText(baseText:String, id:String, theDir:String = "", getModText:String->String->String, mergeRules:MergeRules=null):String
	{
		var extension = uExtension(id, true);

		id = stripAssetsPrefix(id);

		var mergeFile = "_merge" + sl() + id;

		if (extension == "xml")
		{
			var mergeText = getModText(mergeFile, theDir);
			return mergeXML(baseText, mergeText, id);
		}
		else if (extension == "tsv")
		{
			var mergeText = getModText(mergeFile, theDir);
			return mergeTSV(baseText, mergeText, id);
		}
		else if (extension == "csv")
		{
			var mergeText = getModText(mergeFile, theDir);
			var csvFormat = (mergeRules != null ? mergeRules.csv : null);
			if(csvFormat == null)
			{
				Polymod.warning("no_csv_format", "No CSV format provided, using default parse format, there could be problems!");
				csvFormat = new CSVParseFormat(",",true);
			}
			return mergeCSV(baseText, mergeText, id, csvFormat);
		}
		else if (extension == "txt")
		{

		}

		return baseText;
	}

	private static function mergeCSV(a:String, b:String, id:String, format:CSVParseFormat)
	{
		var aCSV = CSV.parseWithFormat(a, format);
		var bCSV = CSV.parseWithFormat(b, format);

		for (row in bCSV.grid)
		{
			var flag = row.length > 0 ? row[0] : "";
			if (flag != "")
			{
				for (i in 0...aCSV.grid.length)
				{
					var otherRow = aCSV.grid[i];
					var otherFlag = otherRow[0];
					if (flag == otherFlag)
					{
						for (j in 0...row.length)
						{
							if (j < otherRow.length)
							{
								otherRow[j] = row[j];
							}
						}
					}
				}
			}
		}

		var result = printCSV(aCSV, format);

		return result;
	}

	private static function mergeTSV(a:String, b:String, id:String):String
	{
		var aTSV = TSV.parse(a);
		var bTSV = TSV.parse(b);

		for (row in bTSV.grid)
		{
			var flag = row.length > 0 ? row[0] : "";
			if (flag != "")
			{
				for (i in 0...aTSV.grid.length)
				{
					var otherRow = aTSV.grid[i];
					var otherFlag = otherRow[0];
					if (flag == otherFlag)
					{
						for (j in 0...row.length)
						{
							if (j < otherRow.length)
							{
								otherRow[j] = row[j];
							}
						}
					}
				}
			}
		}

		var result = printTSV(aTSV);

		return result;
	}

	public static function printCSV(csv:CSV, format:CSVParseFormat):String
	{
		var buf = new StringBuf();

		var delimeter = format.delimeter;
		var lf = 0x0A;
		var dq = 0x22;

		for (i in 0...csv.fields.length)
		{
			buf.add(csv.fields[i]);
			if (i != csv.fields.length - 1)
			{
				buf.add(delimeter);
			}
		}

		var strSoFar = buf.toString();

		if (strSoFar.indexOf("\n") == -1)
		{
			buf.add(Std.string("\r\n"));
		}

		var grid = csv.grid;

		for (iy in 0...grid.length)
		{
			var row = grid[iy];
			for (ix in 0...row.length)
			{
				var cell = row[ix];
				if(format.quotedCells){
					buf.addChar(dq);
				}
				Utf8.iter(cell, function(char:Int)
				{
					buf.addChar(char);
				});
				if(format.quotedCells){
					buf.addChar(dq);
				}
				if (ix != row.length - 1)
				{
					buf.add(delimeter);
				}
			}
			if (iy != grid.length -1)
			{
				buf.add(Std.string("\r\n"));
			}
		}

		return buf.toString();
	}

	public static function printTSV(tsv:TSV):String
	{
		var buf = new StringBuf();

		var tab = 0x09;
		var lf = 0x0A;

		for (i in 0...tsv.fields.length)
		{
			buf.add(tsv.fields[i]);
			if (i != tsv.fields.length - 1)
			{
				buf.addChar(tab);
			}
		}

		var strSoFar = buf.toString();

		if (strSoFar.indexOf("\n") == -1)
		{
			buf.add(Std.string("\r\n"));
		}

		var grid = tsv.grid;

		for (iy in 0...grid.length)
		{
			var row = grid[iy];
			for (ix in 0...row.length)
			{
				var cell = row[ix];
				Utf8.iter(cell, function(char:Int)
				{
					buf.addChar(char);
				});
				if (ix != row.length - 1)
				{
					buf.addChar(tab);
				}
			}
			if (iy != grid.length -1)
			{
				buf.add(Std.string("\r\n"));
			}
		}

		return buf.toString();
	}

	public static function mergeXML(a:String, b:String, id:String):String
	{
		var ax:Xml = null;
		var bx:Xml = null;

		try
		{
			ax = Xml.parse(a);
			bx = Xml.parse(b);
		}
		catch (msg:Dynamic)
		{
			throw "Error parsing XML files during merge (" + id + ") " + msg;
		}

		try
		{
			XMLMerge.mergeXMLNodes(ax, bx);
		}
		catch (msg:Dynamic)
		{
			throw "Error combining XML files during merge (" + id + ") " + msg;
		}

		if (ax == null)
		{
			return a;
		}

		var result = haxe.xml.Printer.print(ax);

		return result;
	}

	public static function appendText(baseText:String, id:String, theDir:String, getModText:String->String->String):String
	{
		var extension = uExtension(id, true);

		id = stripAssetsPrefix(id);

		if (extension == "xml")
		{
			var appendText = getModText("_append" + sl() + id, theDir);

			switch(id)
			{
				/*
				//game-specific cruft from defender's quest
				case "game_progression.xml":
					return appendSpecialXML(baseText, appendText, ["<plotlines>"], ["</plotlines>"]);
				*/
				default:
					return appendXML(baseText, appendText);
			}
		}
		else if(extension == "csv" || extension == "tsv" || extension == "txt")
		{
			var appendText = getModText("_append" + sl() + id, theDir);

			var lastChar = uCharAt(baseText, uLength(baseText) - 1);
			var lastLastChar = uCharAt(baseText, uLength(baseText) - 1);
			var joiner = "";

			var endLine = "\n";

			var crIndex = uIndexOf(baseText, "\r");
			var lfIndex = uIndexOf(baseText, "\n");

			if (crIndex != -1)
			{
				if (lfIndex == crIndex + 1)
				{
					endLine = "\r\n";
				}
			}

			if (lastChar != "\n")
			{
				joiner = endLine;
			}

			if (extension == "tsv" || extension == "csv")
			{
				var otherEndline = endLine == "\n" ? "\r\n" : "\n";
				appendText = uSplitReplace(appendText, otherEndline, endLine);
			}

			var returnText = uCombine([baseText, joiner, appendText]);

			return returnText;
		}
		else if (extension == "json")
		{
			//TODO
		}

		return baseText;
	}

	public static function appendSpecialXML(a:String, b:String, headers:Array<String>, footers:Array<String>):String
	{
		a = stripXML(a, true, true, headers, footers);
		b = stripXML(b, true, true, headers, footers);

		var txt = '<?xml version="1.0" encoding="utf-8" ?>';
		txt = uCat(txt, "<data>");
		txt = uCat(txt, a);
		txt = uCat(txt, b);
		txt = uCat(txt, "</data>");

		return txt;
	}

	public static function appendXML(a:String, b:String):String
	{
		a = stripXML(a, false, true);
		b = stripXML(b, true, false);

		var txt = uCat(a, b);

		return txt;
	}

	public static function stripComments(txt:String):String
	{
		var start = uIndexOf(txt,"<!--");
		var end   = uIndexOf(txt,"-->");
		while (start != -1 && end != -1)
		{
			var len    = uLength(txt);
			var before = uSubstr(txt, 0, start);
			var after  = uSubstr(txt, end + 3, len - (end + 3));
			txt = uCat(before, after);
			start = uIndexOf(txt,"<!--");
			end   = uIndexOf(txt,"-->");
		}
		return txt;
	}

	public static function trimLeadingWhiteSpace(txt:String):String
	{
		var white=["\r","\n"," ","\t"];
		var len = uLength(txt);
		for (w in white)
		{
			while (uIndexOf(txt, w) == 0)
			{
				txt = uSubstr(txt,1,len-1);
				len--;
			}
		}
		return txt;
	}

	public static function trimTrailingWhiteSpace(txt:String):String
	{
		var white=["\r","\n"," ","\t"];
		var len = uLength(txt);
		for (w in white)
		{
			while (uCharAt(txt, len - 1) == w)
			{
				txt = uSubstr(txt,0,len-1);
				len--;
			}
		}
		return txt;
	}

	public static function stripXML(txt:String, stripHeader:Bool=true, stripFooter:Bool=true, headers:Array<String>=null, footers:Array<String>=null):String
	{
		txt = stripComments(txt);

		if (stripHeader)
		{
			if (uIndexOf(txt, "<?xml") == 0)
			{
				var i = uIndexOf(txt, ">");
				txt = uSubstr(txt, i+1, uLength(txt) - (i+1));
				txt = trimLeadingWhiteSpace(txt);
			}
			if (uIndexOf(txt, "<data") == 0)
			{
				var i = uIndexOf(txt, ">");
				txt = uSubstr(txt, i+1, uLength(txt) - (i+1));
				txt = trimLeadingWhiteSpace(txt);
			}
			if (headers != null)
			{
				for (header in headers)
				{
					if (uIndexOf(txt, header) == 0)
					{
						var i = uIndexOf(txt, ">");
						txt = uSubstr(txt, (i + 1), uLength(txt) - (i+1));
						txt = trimLeadingWhiteSpace(txt);
					}
				}
			}
		}
		if (stripFooter)
		{
			txt = trimTrailingWhiteSpace(txt);
			var ulen = uLength(txt);
			if (uLastIndexOf(txt, "</data>") == ulen - 7)
			{
				txt = uSubstr(txt, 0, ulen - 7);
			}
			if (footers != null)
			{
				for (footer in footers)
				{
					txt = trimTrailingWhiteSpace(txt);
					var ulen = uLength(txt);
					var footerlen = uLength(footer);
					if (uLastIndexOf(txt, footer) == ulen - footerlen)
					{
						txt = uSubstr(txt, 0, ulen - footerlen);
					}
				}
			}
		}
		return txt;
	}

	public static inline function hasMerge(id:String, theDir:String = ""):Bool
	{
		return hasSpecial(id, "_merge", theDir);
	}

	private static inline function hasAppend(id:String, theDir:String = ""):Bool
	{
		return hasSpecial(id, "_append", theDir);
	}

	public static inline function stripAssetsPrefix(id:String):String
	{
		if (uIndexOf(id, "assets/") == 0)
		{
			id = uSubstring(id, 7);
		}
		return id;
	}

	public static function hasSpecial(id:String, special:String = "", theDir:String = ""):Bool
	{
		#if sys
		id = stripAssetsPrefix(id);
		var thePath = uCombine([theDir, sl(), special, sl(), id]);
		return fileSystem.exists(thePath);
		#else
		return false;
		#end

	}

	public static function pathJoin(a:String, b:String):String
	{
		var aSlash = (uLastIndexOf(a,"/") == uLength(a) -1 || uLastIndexOf(a,"\\") == uLength(a) -1);
		var bSlash = (uIndexOf(b,"/") == 0 || uIndexOf(b,"\\") == 0);
		var str = "";
		if(aSlash || bSlash)
		{
			str = Util.uCombine([a,b]);
		}
		else
		{
			str = Util.uCombine([a,sl(),b]);
		}
		str = cleanSlashes(str);
		return str;
	}

	public static function cleanSlashes(str:String):String
	{
		str = uSplitReplace(str, "\\", "/");
		str = uSplitReplace(str, "//", "/");
		return str;
	}

	public static function sl():String
	{
		return "/";
	}

	@:access(haxe.xml.Xml)
	public static inline function copyXml(data:Xml, parent:Xml = null):Xml
	{
		var c:Xml = null;
		if (data.nodeType == Xml.Element)
		{
			c = Xml.createElement(data.nodeName);
			for (att in data.attributes())
			{
				c.set(att, data.get(att));
			}
			for (el in data.elements())
			{
				c.addChild(copyXml(el,c));
			}
		}
		else if(data.nodeType == Xml.PCData)
		{
			c = Xml.createPCData(data.nodeValue);
		}
		else if(data.nodeType == Xml.CData)
		{
			c = Xml.createCData(data.nodeValue);
		}
		else if(data.nodeType == Xml.Comment)
		{
			c = Xml.createComment(data.nodeValue);
		}
		else if(data.nodeType == Xml.DocType)
		{
			c = Xml.createDocType(data.nodeValue);
		}
		else if(data.nodeType == Xml.ProcessingInstruction)
		{
			c = Xml.createProcessingInstruction(data.nodeValue);
		}
		else if(data.nodeType == Xml.Document)
		{
			c = Xml.createDocument();
			for (el in data.elements())
			{
				c.addChild(copyXml(el,c));
			}
		}
		@:privateAccess c.parent = parent;
		return c;
	}

	/*****UTF shims*****/

	public static function uCat(a:String, b:String):String
	{
		var sb = new StringBuf();
		sb.add(Std.string(a));
		sb.add(Std.string(b));
		return sb.toString();
	}

	public static function uCharAt(str:String, index:Int):String
	{
		#if unifill
		return Unifill.uCharAt(str, index);
		#else
		return str.charAt(index);
		#end
	}

	public static function uCombine(arr:Array<String>):String
	{
		var sb = new StringBuf();
		for (str in arr)
		{
			sb.add(Std.string(str));
		}
		return sb.toString();
	}

	public static function uExtension(str:String, lowerCase:Bool=false):String
	{
		var i = uLastIndexOf(str, ".");
		var extension = uSubstr(str, i + 1, uLength(str) - (i + 1));
		if (lowerCase)
		{
			extension = extension.toLowerCase();
		}
		return extension;
	}

	public static function uIndexOf(str:String, substr:String, ?startIndex:Int):Int
	{
		#if unifill
		return Unifill.uIndexOf(str, substr, startIndex);
		#else
		return str.indexOf(substr, startIndex);
		#end
	}

	public static function uLastIndexOf(str:String, value:String, ?startIndex:Int):Int
	{
		#if unifill
		return Unifill.uLastIndexOf(str, value, startIndex);
		#else
		return str.lastIndexOf(value, startIndex);
		#end
	}

	public static function uLength(str:String):Int
	{
		#if unifill
		return Unifill.uLength(str);
		#else
		return str.length;
		#end
	}

	public static function uPathPop(str:String):String
	{
		#if unifill
		var path = Unifill.uSplit(str,"/");
		path.pop();
		return path.join("/");
		#else
		var path = str.split("/");
		path.pop();
		return path.join("/");
		#end
	}

	public static function uSplit(str:String, substr:String):Array<String>
	{
		#if unifill
		return Unifill.uSplit(str, substr);
		#else
		return str.split(substr);
		#end
	}

	public static function uSplitReplace(s:String, substr:String, by:String):String
	{
		if (uIndexOf(s, substr) == -1) return s;

		var arr = uSplit(s, substr);

		if (arr == null || arr.length < 2) return s;

		var sb:StringBuf = new StringBuf();
		for (i in 0...arr.length)
		{
			var bit = arr[i];
			sb.add(bit);
			if (i != arr.length - 1)
			{
				sb.add(by);
			}
		}

		return sb.toString();
	}

	public static function uSubstr(str:String, pos:Int, ?len:Int):String
	{
		#if unifill
		return Unifill.uSubstr(str, pos, len);
		#else
		return str.substr(pos, len);
		#end
	}

	public static function uSubstring(str:String, startIndex:Int, ?endIndex:Int):String
	{
		#if unifill
		return Unifill.uSubstring(str, startIndex, endIndex);
		#else
		return str.substring(startIndex, endIndex);
		#end
	}
}