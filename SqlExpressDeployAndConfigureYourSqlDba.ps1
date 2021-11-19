#param
#(
#  [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$ServerInstance
#)

function Invoke-SqlQueries   
{
<#
.SYNOPSIS
    Allows running queries to be run against into SQL Server into two modes.
    One mode allows PowerShell to recover data return by a selected result set the other display all messages and errors and queries in error.

    Author : Maurice Pelchat : This code is provide as-is as an example.  
.DESCRIPTION
    Invoke-SqlQueries function uses Sql .Net Client, to process queries, and messageHandler to catch all messages
.PARAMETER queries
    Allow specifying a queries batches to be run. GO keyword on a line makes queries submitted separatedly as separate batches
.PARAMETER inputFile
    Allow specifying input file as the source of queries
.PARAMETER database
    Allow to specify other database as the default connection database
.PARAMETER ServerInstance
    Allow to specify the sql instance as server\instance
.PARAMETER GetResultSet
    Allow to choose among result sets returned by sql queries to one to be returned as an Powershell object which expose rows content
.EXAMPLE 
    Runs a script file using current windows user with enough message details to diagnose problems (queries with errors are displayed) 
    Invoke-SqlQueries -inputFile ".\YourSQLDba_InstallOrUpdateScript.sql" -serverInstance ".\isql2012" 
.EXAMPLE
    Obtains database file information from database file using current windows user
    $pathBkps="C:\isql2012\backups\myDb.bak"
    $db = "MyDb"
    $sql = 
    @"
    RESTORE FileListOnly 
    FROM  DISK = N'$PathBkps$db.bak'
    "@
    $BkpInfo = Invoke-SqlQueries -ServerInstance $ServerInstance -Database Master -GetResultSet 1 -Queries $sql 
    #
    # Filter row set that we assumes in which there is only two rows
    #
    $Data = $BkpInfo | Where-Object -Property Type -In -Value 'D' | Select-Object -Property LogicalName, PhysicalName
    $Logs = $BkpInfo | Where-Object -Property Type -In -Value 'L' | Select-Object -Property LogicalName, PhysicalName
    Write-Host "Data file logical name : $($Data.LogicalName) Physical name : $($Data.PhysicalNam)"
    Write-Host "Log  file logical name : $($Logs.LogicalName) Physical name : $($Logs.PhysicalNam)"
.NOTES
    When invoked with -GetResultSet n running queries are stopped when the nth result set is returned.  
    When results sets are returned they are returned as an hash table that can be processed through PowerShell means as for example piping to Where-Object, Select-Object etc.
#>
    [CmdletBinding()]
    param 
    (
      [string]$queries=""
    , [string]$inputFile=""
    , [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$serverInstance
    , [string]$Database
    , [string]$User = ""
    , [string]$Pwd = ""
    # If specified > 0 the nth result set returned is returned as an output hash table.  
    # This allows powerShell code to read database content from SQL Queries
    , [int]$GetResultSet=-1  
    )

    If ($inputFile -ne "") 
    {
        Write-Host "------------------------------------------------------"
        Write-Host "Query file : $inputFile to be run on $serverInstance\$Database" 
        Write-Host "------------------------------------------------------"
        $script = Get-Content $inputFile -ReadCount 0 | Out-String
        $SqlBatches = $script -split "`nGO"  # split queries between GO in separated bacth
    }
    Else
    {
        Write-Host "Query to be run on $serverInstance\$Database"
        Write-Host "------------------------------------------------------"
        Write-Host $queries
        Write-Host "------------------------------------------------------"
        $SqlBatches = @()
        $SqlBatches += $queries -split "`nGO"  # split queries between GO in separated bacth
    }

    $global:Invoke_SqlQueries_SqlErrCount = 0

    $sql = ""  # used by message handler to display query in error
    If ($user -ne "")
    {
        $SqlCon = new-object System.Data.SqlClient.SQLConnection("Data Source=$server;User=$User;Password=$pwds;Initial Catalog=$database");
    }
    Else
    {
        $SqlCon = new-object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database");
    }

    
    # ---------------------------------------------------------------------------------
    # Here we define message handler for the connection
    # ---------------------------------------------------------------------------------
    $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] `
    {
        param($sender, $event) 

        If ($event.Errors.count -eq 0) # handler can be invoked with no messages
        {
          return
        }

        Foreach ($Err in $event.Errors) # handler can be have many messages to process, event for a single query
        {
            If ($err.Message.Length -gt 0)  # check if message have some text
            { 
                If (($Err.Class -ge 0 ) -and ($err.Class -le 10))  # just informational message
                {
                    Write-Host $Err.Message -ForegroundColor cyan
                }
                else # one error message
                {
                    $global:Invoke_SqlQueries_SqlErrCount++
                    If ($sql -ne "")
                    {
                        Write-Host -ForegroundColor Green $Sql
                        $sql = ""
                    }
                    # error message may describe error in stored procedure which is different than within a batch
                    If  ($err.Procedure.Length -gt 0)  
                    {
                        Write-Host -ForegroundColor Red "erreur: $($err.Number) Severity $($err.Class) State $($err.State) Msg: $($err.Message) In $($err.Procedure) at line $($err.LineNumber)"
                    }
                    else # or just in a batch of one or more queries
                    {
                        Write-Host -ForegroundColor Red "erreur: $($err.Number) Severity $($err.Class) State $($err.State) Msg: $($err.Message) at line $($err.LineNumber)"
                    }
                } # format informational or error message
            } 
        } # loop for each error
    } # error handler code ends here

    $SqlCon.add_InfoMessage($handler)  # plug the handler to the connection
    $SqlCon.FireInfoMessageEventOnUserErrors = $true # activate it
    $SqlCon.Open(); # open the connection 

    # to know how many errors are caugth by the handler
    $rsCount = 0  # count result set to track which one it is matching -GetResultSet
    Foreach ($batch in $SqlBatches)
    {
        $Sql = $Batch
        $cmd = new-object System.Data.SqlClient.SqlCommand($batch, $SqlCon);
        $reader = $cmd.ExecuteReader()
        do
        {
            $rs = @() # empty table

            while ($reader.Read())
            {
                $row = @{}  # hash table that associate column name to its value
                for ($i = 0; $i -lt $reader.FieldCount; $i++)
                {
                    $colName = $reader.GetName($i)  # get column name, handle un-named columns
                    If ($colName -EQ "") { $colName = "NoName"+$i.ToString("D4") }
                    $row[$colName] = $reader.GetValue($i) # add column and its value
                }
                # add row object which is an hash table to $rs which is a table (here of hash table)
                $rs += , (new-object psobject -property $row)            
            }
            If ($global:Invoke_SqlQueries_SqlErrCount -gt 0) # if some errors are encountered by handler which increment $errCount
            {
                Throw "See error when running previous query, and ignore error on this query" # throw error
            }
            If ($reader.FieldCount>0) # If there is some columns this is a result set
            { 
                $rsCount++ 

                If ($GetResultSet -eq -1) # if no result set is asked to be returned as an object, display it here
                {
                    $rs | Format-Table -AutoSize | Out-Host  
                }
            } 

        } while ($reader.nextResult());  # process next result set if there is any

        $reader.Close(); # close reader which is different than closing connection

        # if asked for a nth result set and it is, return it, break loop processing of queries
        If ($rsCount -eq $GetResultSet)
        {
            $rs # retourner result set tel quel et on termine le processus
            Break
        }
    }

    $SqlCon.FireInfoMessageEventOnUserErrors = $False     # disable message handler
    $SqlCon.Close(); # close connection

}
cls
Invoke-SqlQueries -inputFile ".\YourSQLDba_InstallOrUpdateScript.sql" -serverInstance ".\isql2012" 
#Get-Help Invoke-Queries
