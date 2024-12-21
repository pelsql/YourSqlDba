using System;
using System.IO;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.Collections;


struct FileDetails {
    public string FileName; 
    public string FileExtension; 
    public long FileSizeByte; 
    public DateTime ModifiedDate;
    public DateTime CreatedDate; 
}


namespace Clr_FileOperations
{
    // implements file operations
    //  stored procedure and function names are self explanatory
    public class FileOpCs
    {
        [SqlProcedure(Name = "Clr_CreateFolder")]
        public static void Clr_CreateFolder(string FolderPath, out string ErrorMessage)
        {
            char[] charsToTrim = {'\\'};

            if(FolderPath.EndsWith("\\"))
                FolderPath = FolderPath.TrimEnd(charsToTrim);
            try
            {
                System.IO.Directory.CreateDirectory(FolderPath);
                ErrorMessage = "";
            }
            catch (Exception ex)
            {
                ErrorMessage = ex.Message;
            }
        }

        [SqlProcedure(Name = "Clr_DeleteFolder")]
        public static void Clr_DeleteFolder(string FolderPath, out string ErrorMessage)
        {
            char[] charsToTrim = {'\\'};

            if (FolderPath.EndsWith("\\"))
                FolderPath = FolderPath.TrimEnd(charsToTrim);
            try
            {
                System.IO.Directory.Delete(FolderPath);
                ErrorMessage = "";
            }
            catch (Exception ex){
                ErrorMessage = ex.Message;
            }
        }


        [SqlProcedure(Name = "Clr_RenameFolder")]
        public static void Clr_RenameFolder(string FolderPath, string NewFolderName, out string ErrorMessage)
        {
           char[] charsToTrim = {'\\'};
           if (FolderPath.EndsWith("\\"))
                 FolderPath = FolderPath.TrimEnd(charsToTrim);
           try 
           {
                System.IO.Directory.Move(FolderPath, System.IO.Path.GetDirectoryName(FolderPath) + "\\" + NewFolderName);
                ErrorMessage = "";
           }
           catch (Exception ex){
               ErrorMessage = ex.Message;
           }
        }


        [SqlFunction(Name = "Clr_GetFolderList", TableDefinition = "FileName nvarchar(255)", FillRowMethodName = "Clr_GetFolderListFillRow")]
        public static IEnumerable Clr_GetFolderList(string FolderPath, String SearchPattern) 
        {
           string[] FilesIn;
           ArrayList FilesOut = new ArrayList();


           char[] charsToTrim = {'\\'};
           if (FolderPath.EndsWith("\\"))
               FolderPath = FolderPath.TrimEnd(charsToTrim);

           try
           {
               FilesIn = System.IO.Directory.GetFiles(FolderPath, SearchPattern);

               foreach(string f in FilesIn)
                   FilesOut.Add(System.IO.Path.GetFileName(f));
                
           }
           catch (Exception ex){
               FilesOut.Clear();
               FilesOut.Add("<ERROR>");
               FilesOut.Add(ex.Message);
           }

           return FilesOut;
        }
        // method defined for the above function
        public static void Clr_GetFolderListFillRow(Object obj, out SqlChars FileName)
        {
           string File = Convert.ToString(obj);
           FileName = new SqlChars(File);
        }

        [SqlFunction(Name = "Clr_GetFolderListDetailed", TableDefinition = "FileName nvarchar(255), FileExtension nvarchar(255), FileSizeByte bigint, ModifiedDate datetime, CreatedDate datetime", FillRowMethodName = "Clr_GetFolderListDetailedFillRow")]
        public static IEnumerable Clr_GetFolderListDetailed(string FolderPath, string SearchPattern) 
        {
           string[] FilesIn;
           ArrayList FilesOut = new ArrayList();
           FileDetails fd;
           FileInfo fi;

           char[] charsToTrim = {'\\'};

           if (FolderPath.EndsWith("\\"))
               FolderPath = FolderPath.TrimEnd(charsToTrim);
           try 
           {
               FilesIn = System.IO.Directory.GetFiles(FolderPath, SearchPattern);
               foreach (string f in FilesIn)
               {
                   fi = new FileInfo(f);
                   fd.FileName = fi.Name;
                   fd.FileExtension = fi.Extension;
                   fd.FileSizeByte = fi.Length;
                   fd.ModifiedDate = fi.LastWriteTime;
                   fd.CreatedDate = fi.CreationTime;
                   FilesOut.Add(fd);
               }
           }
           catch (Exception ex) 
           {
               FilesOut.Clear();
               fd.FileName = "<ERROR>";
               fd.FileExtension = "ERR";
               fd.FileSizeByte = 0;
               fd.ModifiedDate = Convert.ToDateTime("1900-01-01");
               fd.CreatedDate = Convert.ToDateTime("1900-01-01");
               FilesOut.Add(fd);
               fd.FileName = ex.Message;
               FilesOut.Add(fd);
           }
           return FilesOut;
        }

        // method defined for the above function
        public static void Clr_GetFolderListDetailedFillRow(Object obj, out SqlChars FileName, out SqlChars FileExtension, out SqlInt64 FileSizeByte, out SqlDateTime ModifiedDate, out SqlDateTime CreatedDate)
        {
           FileDetails fd = (FileDetails)obj;

           FileName = new SqlChars(fd.FileName);
           FileExtension = new SqlChars(fd.FileExtension);
           FileSizeByte = new SqlInt64(fd.FileSizeByte);
           ModifiedDate = new SqlDateTime(fd.ModifiedDate);
           CreatedDate = new SqlDateTime(fd.CreatedDate);
        }

        [SqlProcedure(Name = "Clr_FileExists")]
        public static void Clr_FileExists(string FilePath, out bool FileExistsFlag, out string ErrorMessage)
        {
           try 
           {
               FileExistsFlag = System.IO.File.Exists(FilePath);
               ErrorMessage = "";
           }
           catch(Exception ex)
           {
               FileExistsFlag = false; 
               ErrorMessage = ex.Message;
           }
        }

        [SqlProcedure(Name = "Clr_DeleteFile")]
        public static void Clr_DeleteFile(string FilePath, out string ErrorMessage)
        {
           try 
           {
               System.IO.File.Delete(FilePath);
               ErrorMessage = "";
           }
           catch (Exception ex)
           {
               ErrorMessage = ex.Message;
           }
        }


        [SqlProcedure(Name = "Clr_DeleteFiles")]
        public static void Clr_DeleteFiles(string FolderPath, string SearchPattern, out string ErrorMessage)
        {
           string[] Files;
           char[] charsToTrim = {'\\'};

           if (FolderPath.EndsWith("\\"))
               FolderPath = FolderPath.TrimEnd(charsToTrim);
           try {
               Files = System.IO.Directory.GetFiles(FolderPath, SearchPattern);
               foreach(string f in Files)
                   System.IO.File.Delete(f);
               ErrorMessage = "";
                
           }
           catch (Exception ex)
           {
               ErrorMessage = ex.Message;
           }
        }

        [SqlProcedure(Name = "Clr_ChangeFileExtensions")]
        public static void Clr_ChangeFileExtensions(string FolderPath, string OldExtension, string NewExtension, out string ErrorMessage)
        {
           string[] Files;
           char[] charsToTrim = {'\\'};

           if (FolderPath.EndsWith("\\"))
               FolderPath = FolderPath.TrimEnd(charsToTrim);
           try 
           {
               Files = System.IO.Directory.GetFiles(FolderPath, "*." + OldExtension);
               foreach (string f in Files)
                   System.IO.File.Move(f, FolderPath + "\\" + System.IO.Path.GetFileNameWithoutExtension(f) + "." + NewExtension);
               ErrorMessage = "";
                
           }
           catch (Exception ex) 
           {
               ErrorMessage = ex.Message;
           }
        }

        [SqlProcedure(Name = "Clr_RenameFile")]
        public static void Clr_RenameFile(string FilePath, string NewFileName, out string ErrorMessage)
        {
            try {
                System.IO.File.Move(FilePath, FilePath.Replace(System.IO.Path.GetFileName(FilePath), NewFileName));
                ErrorMessage = "";
            }
            catch (Exception ex) {
                ErrorMessage = ex.Message;
            }

        }

        [SqlProcedure(Name = "Clr_CopyFile")]
        public static void Clr_CopyFile(string SourceFilePath, string DestinationFilePath, out string ErrorMessage)
        {

           char[] charsToTrim = { '\\' };

           try
           {
              System.IO.File.Copy (SourceFilePath, DestinationFilePath);
              ErrorMessage = "";
           }
           catch (Exception ex)
           {
              ErrorMessage = ex.Message;
           }
        }

        [SqlProcedure(Name = "Clr_MoveFile")]
        public static void Clr_MoveFile(string SourceFilePath, string DestinationFolderPath, out string ErrorMessage)
        {

            char[] charsToTrim = {'\\'};

            if (DestinationFolderPath.EndsWith("\\"))
                DestinationFolderPath = DestinationFolderPath.TrimEnd(charsToTrim);
            

            try {
                System.IO.File.Move(SourceFilePath, DestinationFolderPath + "\\" + System.IO.Path.GetFileName(SourceFilePath));
                ErrorMessage = "";
            }
            catch (Exception ex) 
            {
                ErrorMessage = ex.Message;
            }
        }

        [SqlProcedure(Name = "Clr_MoveFiles")]
        public static void Clr_MoveFiles(string FolderPath, string SearchPattern, string DestinationFolderPath, out string ErrorMessage)
        {
           string [] Files;
           char[] charsToTrim = {'\\'};

           if (FolderPath.EndsWith("\\"))
               FolderPath = FolderPath.TrimEnd(charsToTrim);

           if (DestinationFolderPath.EndsWith("\\"))
               DestinationFolderPath = DestinationFolderPath.TrimEnd(charsToTrim);

           try 
           {
               Files = System.IO.Directory.GetFiles(FolderPath, SearchPattern);
               foreach (string f in Files)
                   System.IO.File.Move(f, DestinationFolderPath + "\\" + System.IO.Path.GetFileName(f));
               ErrorMessage = "";
           }
           catch (Exception ex) 
           {
               ErrorMessage = ex.Message;
           }
        }

        [SqlProcedure(Name = "Clr_GetFileSizeByte")]
        public static void Clr_GetFileSizeByte(string FilePath, out Int64 FileSizeByte, out string ErrorMessage)
         {
            FileInfo fi;

            try 
            {
                fi = new FileInfo(FilePath);
                FileSizeByte = fi.Length;
                ErrorMessage = "";
            }
            catch (Exception ex)
            {
                FileSizeByte = 0;
                ErrorMessage = ex.Message;
            }
        }


        [SqlProcedure(Name = "Clr_GetFileDateModified")]
        public static void Clr_GetFileDateModified(string FilePath, out DateTime ModifiedDate, out string ErrorMessage)
        {
           ModifiedDate = Convert.ToDateTime("1900-01-01");
           ErrorMessage = "";

           try 
           {
               if(System.IO.File.Exists(FilePath) )
                   ModifiedDate = System.IO.File.GetLastWriteTime(FilePath);
               else                  
                   ErrorMessage = "Path not found.";
           }
           catch (Exception ex) 
           { 
               ErrorMessage = ex.Message;
           }
        }

        [SqlProcedure(Name = "Clr_GetFileDateCreated")]
        public static void Clr_GetFileDateCreated(string FilePath, out DateTime CreatedDate, out string ErrorMessage)
        {
           CreatedDate = Convert.ToDateTime("1900-01-01");
           ErrorMessage = "";

           try 
           {
               if (System.IO.File.Exists(FilePath))
                   CreatedDate = System.IO.File.GetCreationTime(FilePath);
               else
                   ErrorMessage = "Path not found.";

           }
           catch (Exception ex) 
           {
              ErrorMessage = ex.Message;
           }
        }


        [SqlProcedure(Name = "Clr_AppendStringToFile")]
        public static void Clr_AppendStringToFile(string FilePath, string FileContents, out string ErrorMessage)
        {
            ErrorMessage = "";

            try
            {
                System.IO.File.AppendAllText(FilePath, FileContents);
            }
            catch (Exception ex)
            {
                ErrorMessage = ex.Message;
            }
        }

        [SqlProcedure(Name = "Clr_WriteStringToFile")]
        public static void Clr_WriteStringToFile(string FilePath, string FileContents, out string ErrorMessage)
        {
            ErrorMessage = "";

            try
            {
                System.IO.File.WriteAllText(FilePath, FileContents);
            }
            catch (Exception ex)
            {
                ErrorMessage = ex.Message;
            }
        }
    }
}
