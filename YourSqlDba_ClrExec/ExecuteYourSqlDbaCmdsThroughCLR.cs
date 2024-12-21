using System;
using System.Data;
using System.Security;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Text;
using System.Xml;
using System.IO;

public class ExecuteYourSqlDbaCmdsThroughCLR
{
   // helper to escape special char sot they will be suitable in XML, as the output of a query for example
   [Microsoft.SqlServer.Server.SqlFunction(Name = "Clr_RemoveCtlChar", IsDeterministic = true, IsPrecise = true)]
   [return: SqlFacet(MaxSize = -1)] // hint Sql that the return valus is nvarchar(max), do about the same for the input parameter
   public static SqlString Clr_RemoveCtlChar([SqlFacet(MaxSize = -1)] SqlString beforeEscape)
   {
    // don't really escape usual escape char because SQL does it automatically. Try special escape char like nchar(19) that are not caught by SQL.
    // I must then, put the most common back on, to avoid escaping over the already escaped

    String inString = beforeEscape.Value;

    if (inString == null) return null;

    StringBuilder newString = new StringBuilder();
    char ch;

    for (int i = 0; i < inString.Length; i++)
    {

     ch = inString[i];

     if (!char.IsControl(ch))
     {
      newString.Append(ch);
     }
    }
    return newString.ToString();
   }

   // helper to present pettry print of an XML doc.  Input is an xml converted into string
   [Microsoft.SqlServer.Server.SqlFunction(Name = "Clr_XmlPrettyPrint", IsDeterministic = true, IsPrecise = true)]
   [return: SqlFacet(MaxSize = -1)] // hint Sql that the return valus is nvarchar(max), do about the same for the input parameter
   public static SqlString Clr_XmlPrettyPrint([SqlFacet(MaxSize = -1)] SqlXml Xml)
   {
    /// Returns formatted xml string (indent and newlines) from XML parameter
    /// for display in eg textboxes.
    /// </summary>

    //load unformatted xml into a dom
    XmlDocument xd = new XmlDocument();
    //xd.LoadXml(inString);
    xd.Load(Xml.CreateReader());

    //will hold formatted xml
    StringBuilder sb = new StringBuilder();

    //pumps the formatted xml into the StringBuilder above
    using (StringWriter sw = new StringWriter(sb))
    {

        XmlTextWriter xtw = new XmlTextWriter(sw);

          //we want the output formatted
        xtw.Formatting = Formatting.Indented;

        //get the dom to dump its contents into the xtw 
        xd.WriteTo(xtw);
    }

    //return the formatted xml
    return sb.ToString();
    }

   // implements a suitable way to trap ALL SQL messages which is not easy to do in T-SQL
   // especially when there are errors with backups that implies an OS problem
   // such as inxesitant directory, or lack of disk space or IO error.
   [SqlProcedure(Name = "Clr_ExecAndLogAllMsgs")]
   public static void Clr_ExecAndLogAllMsgs(SqlChars SqlCmd, out SqlInt32 MaxSeverity, out SqlChars Msgs)
   {
      SqlCommand cmd;
      string LocalMsgs; // must be a local variable to be manipulated before returned by output param
      Int32 LocalMaxSeverity; // must be a local variable to be manipulated before returned by output param

      // Using implies an automatic dispose of the connexion object
      using (SqlConnection conn = new SqlConnection("context connection=true;"))
      {
         try
         {
            // Assumes that "conn" represents a SqlConnection object.
            conn.Open();

            conn.FireInfoMessageEventOnUserErrors = true;  // don't stop on first error message, want info message to catch them all

            // here is the inline delegate trick. This block of code is called back
            // when SQL Info messages are raised (informational or error)
            conn.InfoMessage += delegate(object sender, SqlInfoMessageEventArgs args)
            {
               LocalMaxSeverity = 0;
               String message;
               // use a string builder to cumulate messages
               StringBuilder SbMsgs = new StringBuilder("");
               foreach (SqlError err in args.Errors)
               {
                 if (!(err.Message == null))
                 {
                   message = err.Message;
                   if (err.Class == 0)
                   {
                      // don't put special info for messages produced by the print statement
                      // SbMsgs.AppendFormat("{0} ", message);
                      SbMsgs.AppendLine(message); 
                   }
                   else
                   {
                      if (err.Class > 10) // error messages
                      {
                         string s;
                         if (err.LineNumber > 0)
                         {
                            s = String.Format(" at line {0} in proc {1} ", err.LineNumber, err.Procedure);
                         }
                         else
                         {
                            s = "";
                         }
                         SbMsgs.AppendFormat("Error {0}, Severity {1}, level {2} : {3}{4}", err.Number, err.Class, err.State, message, s);
                         SbMsgs.AppendLine();
                      }
                      else // informational messages
                      {
                         SbMsgs.AppendFormat("Warning Severity {0}, level {1} : {2}", err.Class, err.State, message);
                         SbMsgs.AppendLine();
                      }
                      if (err.Class > LocalMaxSeverity)
                      {
                         LocalMaxSeverity = err.Class; // this allows to know if a real error occured (severity > 10)
                      }
                   }
                 }
               }
               LocalMsgs = SbMsgs.ToString();
            }; // end of inline delegate code to trap and stored informational and error messages
            // execute SP
            using (cmd = new SqlCommand("sp_executeSql", conn))
            {
               string sql;

               LocalMsgs = "";  // avoid compile warnings that says that the variable is not initialized
               LocalMaxSeverity = 0; // avoid compile warnings that says that the variable is not initialized
               sql = new string(SqlCmd.Buffer);
               cmd.CommandType = CommandType.StoredProcedure;
               cmd.Parameters.Add(new SqlParameter("@statement", @SqlCmd));
               cmd.ExecuteNonQuery();
               Msgs = new SqlChars(LocalMsgs.ToCharArray()); // return local value into output parameter
               MaxSeverity = LocalMaxSeverity; // return local value into output parameter
            }
         }
         catch (SqlException ex)
         {
            throw
               new ApplicationException(ex.Message); 
         }
      
      }
   }

}
