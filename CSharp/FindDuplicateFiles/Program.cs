using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace ConsoleUI
{
	class Program
	{
		static void Main(string[] args)
		{
			string rootPath = @"C:\Users\Craig\Documents\PowerShell";
			string[] dirs = Directory.GetDirectories(rootPath, "*", SearchOption.AllDirectories);

			foreach (string dir in dirs)
			{
				Console.WriteLine(dir);
			}
			Console.ReadLine();
		}
	}
}
