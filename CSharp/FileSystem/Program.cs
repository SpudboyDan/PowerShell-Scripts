using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace ConsoleUI
{
	class Program
	{
		static void Main(string[] args)
		{
			string rootPath = @"C:\Users\Craig\Documents\PowerShell";

			// string[] directories = Directory.GetDirectories(rootPath, "*", SearchOption.AllDirectories);

			// foreach (string dir in directories)
			//{
			//	Console.WriteLine(dir);
			//}

			//var files = Directory.GetFiles(rootPath, "*.*", SearchOption.AllDirectories);

			//foreach (string file in files)
			//{
				//Console.WriteLine(file);
				//Console.WriteLine(Path.GetFileName(file));
				//Console.WriteLine(Path.GetFileNameWithoutExtension(file));
				//Console.WriteLine(Path.GetDirectoryName(file));
				//var info = new FileInfo(file);
				//Console.WriteLine($"{ Path.GetFileName(file) }: { info.Length } bytes");
			//}

			//bool directoryExists = Directory.Exists(@"C:\Users\Craig\Documents\PowerShell\SubFolderC");
			//string newPath = @"C:\Users\Craig\Documents\PowerShell\SubFolderC\SubSubFolderD";

			//if (directoryExists)
			//{
			//	Console.WriteLine("The directory exists");
			//}
			//else
			//{
			//	Console.WriteLine("The directory does not exist");
			//	Directory.CreateDirectory(newPath);
			//}

			Console.ReadLine();
		}
	}
}
