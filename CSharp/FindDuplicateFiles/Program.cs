using System;
using System.IO;

public class FileLength
{
	public static void Main()
	{
		// New directory reference
		DirectoryInfo dirInfo = new DirectoryInfo(@"C:\Users\Lane\Documents\PowerShell\Scripts\PowerShell");
		// Reference to each file in that directory
		FileInfo[] fileArray = dirInfo.GetFiles();
		// Display file names and sizes
		Console.WriteLine("The directory {0} contains the following files:", dirInfo.Name);
		foreach (FileInfo fileInf in fileArray)
		{
			Console.WriteLine("The size of {0} is {1} bytes.", fileInf.Name, fileInf.Length);
		}
	}
}
