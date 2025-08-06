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
			string rootPath = @"C:\Users\Craig\Documents\PowerShell\Notes";
			string[] files = Directory.GetFiles(rootPath); 
			string destinationFolder = @"C:\Temp\";
			foreach (string file in files)
			{
				Console.WriteLine(file);
				File.Copy(file, $"{destinationFolder}{ Path.GetFileName(file) }", true);
			}

			Console.ReadLine();
		}
	}
}
