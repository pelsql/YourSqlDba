Drop Proc If Exists dbo.BuildRestoreFromBackupFiles 
GO
Create Proc dbo.BuildRestoreFromBackupFiles 
  -- where .bak file are located (madatory)
  @SourceFolder Nvarchar(512) 
  -- if not specified, restore to the source database
, @DestinationDatabase Sysname = NULL
  -- Adjust logical file name accordingly to system name, not database name, If omitted, database name is used.
, @SystemName sysname = NULL
, @StopAt datetime = NULL
  -- optional string substituions for path name, in case database name or location would change.
, @pathRepFrom1 Nvarchar(512) = NULL, @pathRepTo1 Nvarchar(512) = NULL
, @pathRepFrom2 Nvarchar(512) = NULL, @pathRepTo2 Nvarchar(512) = NULL 
, @pathRepFrom3 Nvarchar(512) = NULL, @pathRepTo3 Nvarchar(512) = NULL
as
Begin
  Set nocount on

  -- Documentation example for CommVault backup files. This procedure is not
  -- installed by YourSqlDba, but uses its version-aware metadata collectors.
  -- It is provided as-is and must be validated against the client's CommVault
  -- file-naming convention in a non-production environment before use.
  If DB_ID(N'YourSqlDba') Is NULL
    Throw 50000, 'YourSqlDba must be installed before using this procedure.', 1;

  If Object_ID(N'YourSqlDba.yMaint.CollectBackupHeaderInfoFromBackupFile') Is NULL
  Or Object_ID(N'YourSqlDba.yMaint.CollectBackupFileListFromBackupFile') Is NULL
    Throw 50000, 'The installed YourSqlDba version does not provide the required backup metadata collectors.', 1;

  If NULLIF(@SourceFolder, N'') Is NULL
    Throw 50000, '@SourceFolder is required.', 1;

  If CharIndex(N'''', @SourceFolder) > 0
    Throw 50000, '@SourceFolder cannot contain an apostrophe.', 1;

  -- Get first file name among backup file which is a full backup
  Declare @FirstFull Nvarchar(512)
  Select Top 1
    @FirstFull=full_filesystem_path
  From
    (Select SourceFolder=@SourceFolder) as Prm
    -- new DM view very useful to list a directory, from SQL2017 RC1
    CROSS APPLY sys.dm_os_enumerate_filesystem(SourceFolder, '*')
  Where
    file_or_directory_name Like '%[_]1[_]Full[_]%'
  Order By
    last_write_time, full_filesystem_path

  If @FirstFull Is NULL
    Throw 50000, 'No CommVault _1_Full_ backup file was found in @SourceFolder.', 1;


  Declare @rc Int
  Exec @rc=YourSqlDba.yMaint.CollectBackupFileListFromBackupFile
    @bkpFile=@FirstFull
  If @rc <> 0 Return

  Exec @rc=YourSqlDba.yMaint.CollectBackupHeaderInfoFromBackupFile
    @bkpFile=@FirstFull
  If @rc <> 0 Return

  Declare @SourceDatabase Sysname
  Select Top 1
    @SourceDatabase=DatabaseName
  From
    YourSqlDba.Maint.TemporaryBackupHeaderInfo
  Where
    spid=@@SPID
  Order By
    Position

  If @SourceDatabase Is NULL
    Throw 50000, 'The source database name could not be read from the first full backup.', 1;

  Set @DestinationDatabase=ISNULL(@DestinationDatabase, @SourceDatabase)
  Declare @QuotedDestinationDatabase Nvarchar(258)=QuoteName(@DestinationDatabase)
  If @QuotedDestinationDatabase Is NULL
    Throw 50000, '@DestinationDatabase is not a valid SQL Server identifier.', 1;

  Select --seqSql, BackupTyp, temps, revSeqSql,
   [--SqlStmtPart]=SqlStmtPart
   -- * -- comment previous column and uncomment this one if trace for debugging is needed
  From
    (
    -- limit the number of file returned in StopAt is specified.
    Select 
      -- get sequence order from restore command to generate.
      seqSql=Row_Number() Over (order by EndOfBkpFromFile)
      -- get sequence order from last to previous, here value 1 is the value of interest that let know we are processing the last file
    , revSeqSql=Row_Number() Over (order by EndOfBkpFromFile desc)  
    , *
    From 
      ( --  build columns with parameters, filename, backup dates, file type
      Select 
          -- this value help to know when we must deal with the generation of first restore
          -- which is different of all other
          FirstCompleteBkpFile = FIRST_VALUE (SrcFile) Over (Order By EndOfBkpFromFile)
          -- this value help to figure out when to specify stopAt. StopAt must be less than actual
          -- end of backup but higher than previous file end of backup. 
        , EndBkpTimeOfPreviousFile = Lag (EndOfBkpFromFile,1,'') Over (Order By EndOfBkpFromFile)
        , Prm.*
        , fld.file_or_directory_name
        , Fld.full_filesystem_path 
        , f.*
        , InfBkpTyp.* 
      from 
        (
        Select 
          SourceFolder=@SourceFolder -- 'P:\RestaurationBakRegard26Nov'
        , DestinationDatabase=@DestinationDatabase
        , QuotedDestinationDatabase=@QuotedDestinationDatabase
        , pathRepFrom1 = ISNULL([@pathRepFrom1],''), pathRepTo1 = ISNULL([@pathRepTo1],'')
        , pathRepFrom2 = ISNULL([@pathRepFrom2],''), pathRepTo2 = ISNULL([@pathRepTo2],'')
        , pathRepFrom3 = ISNULL([@pathRepFrom3],''), pathRepTo3 = ISNULL([@pathRepTo3],'')
        , sourceDatabase=@SourceDatabase
        , SystemName = @SystemName
        , StopAtPrm = CONVERT(nvarchar, @StopAt, 120)
        From
          (Select ForCrossApplySyntaxOnly=1) as ForCrossApplySyntaxOnly
          Cross Apply
          (
          Select 
            [@pathRepFrom1] = @pathRepFrom1 -- 'F:\Data\'
          , [@pathRepTo1]   = @pathRepTo1   -- 'F:\Data\Test\'
          , [@pathRepFrom2] = @pathRepFrom2 -- 'L:\Data\'
          , [@pathRepTo2]   = @pathRepTo2   -- 'L:\Tmp\'
          , [@pathRepFrom3] = @pathRepFrom3 -- NULL
          , [@pathRepTo3]   = @pathRepTo3   -- NULL
          ) as pathRep
        ) as Prm
        cross apply 
        (
        -- there is 2 consecutive file name all identical but with _1_ ou _2_ to differentiate
        -- them because they belong to the same file set, and be put together in the from
        -- statement of the restore cmd.
        -- But we must generate a single restore out of this pair or row
        -- so I filter files by %_1_% and and I'll compute the other name
         Select *
         From sys.dm_os_enumerate_filesystem(SourceFolder, '*') 
         Where file_or_directory_name Like sourceDatabase+'[_]1[_]%'  -- RegardCAL_test_1_Full_Fri_Nov_26_11_32_57_2021.bak
        ) as Fld
        cross apply 
        (
        -- generate second file name from first, so we end by having a single row with info needed for both file name.
        -- we get here file part names to do proper ordering, in which month name is translate to its number
        Select SrcPath1, PosSeqIdOffile, SrcPath2, SrcFile=Fld.file_or_directory_name
             , TimeStampPart, ShortNamePart, _dd_hr_mi_ss_Part, dd_hr_mi_ss_Part, [dd hr:mi:ss Part]
             , YearPart, MoNum, EndOfBkpFromFile
        From 
          (Select forCrossApplySyntaxOnly=1) as forCrossApplySyntaxOnly -- no other use than allow to start next with an APPLY
          CROSS APPLY (Select SrcPath1=full_filesystem_path) as SrcPath1
          CROSS APPLY (Select PosSeqIdOffile= Len(Fld.parent_directory +sourceDatabase)+1) as PosSeqIdOffile
          CROSS APPLY (Select SrcPath2=Stuff(Fld.full_filesystem_path, PosSeqIdOffile,3,'_2_')) as SrcPath2
          -- ex: CommVault naming put timestamp info in the last 24 chars of file name, and we want to work from this
          -- ex: "DbNameXYZ_1_Full_Fri_Dec__3_15_51_35_2021.bak" which gives "Dec__3_15_51_35_2021.bak"
          CROSS APPLY (Select TimeStampPart=RIGHT(Fld.file_or_directory_name,24)) as TimeStampPart
          -- Extract year from timestamp ex: from "Dec__3_15_51_35_2021.bak" get "2021"
          CROSS APPLY (Select YearPart=SUBSTRING(TimeStampPart, 17, 4)) as YearPart
          -- ex: Extract shorten month name from Timestamp "Dec__3_15_51_35_2021.bak" ex: "Dec"
          CROSS APPLY (Select ShortNamePart=Left(TimeStampPart,3)) as ShortNamePart
          -- find matching month number from shorten month name ex: for JAN return 01
          CROSS APPLY (
                      Select MoNum
                      From (Values ('Jan','01'),('Feb','02'),('Mar','03'),('Apr','04'),('may','05'),('jun','06')
                                  ,('jul','07'),('aug','08'),('sep','09'),('oct','10'),('nov','11'),('dec','12')) as MoisEq(MoisStr, MoNum)
                      Where MoisEq.MoisStr = ShortNamePart
                      ) as MoNum
          -- ex: take the numeric part that follow from position 5 over 11 char long "Dec__3_15_51_35_2021.bak" which gives "_3_15_51_35"
          CROSS APPLY (Select _dd_hr_mi_ss_Part=SUBSTRING(TimeStampPart, 5, 11)) as _dd_hr_mi_ss_Part
          -- but it is annoying that it starts sometimes with "_" when it should start with "0"
          -- the goal is to produce a real time part 03 15:51:35, so we generate the corrected value 03_15_51_35
          CROSS APPLY (Select dd_hr_mi_ss_Part=IIF(Left(_dd_hr_mi_ss_Part,1)='_',STUFF(_dd_hr_mi_ss_Part,1,1,'0'),_dd_hr_mi_ss_Part)) as dd_hr_mi_ss_Part
          -- Then next goal is to transform it from "03_15_51_35" to "03 15:51:35" by doing 03:15:51:35 and then "03 15:51:35"
          CROSS APPLY (Select [dd hr:mi:ss Part]=Stuff(Replace(dd_hr_mi_ss_Part,'_',':'),3,1,' ')) as [dd hr:mi:ss Part]
          -- Assemble complete datetime expression from extracted part which give : "2021-12-03 15:51:35"
          CROSS APPLY (Select EndOfBkpFromFile=Convert(Nvarchar(20), YearPart+'-'+MoNum+'-'+[dd hr:mi:ss Part])) as EndOfBkpFromFile
        ) as f
        -- guess restore type because it is in somewhere in the filename l=Fld.full_filesystem_path
        cross apply 
        (
        Select *
        From 
          (
          Values 
            ('full%', 1, 'Database', 'Database')
          , ('differential%', 2, 'differential', 'Database')
          , ('log%', 3, 'log', 'log')
          ) as SeqLLikeRestore(likeForType, SeqBackupTyp, BackupTyp, RestoreTyp)
        Where SrcFile like sourceDatabase+'[_][12][_]'+likeForType
        ) as InfBkpTyp

      ) as Filenames

    -- If StopAt parameter isn't specified include all file
    -- otherwise include files for which timestamp of previous file is still lower than stopAt
    Where (StopAtPrm IS NULL) Or (StopAtPrm IS NOT NULL And StopAtPrm > EndBkpTimeOfPreviousFile )

    ) as fileSubset -- fileSubset it StopAt applies, otherwise complete set

    -------------------------------------------------------------------------------------------------------
    -- BUILDING RESTORE Statements parts IN ORDER OF END OF BACKUP TIME and ORDER OF STATEMENT PARTS
    -------------------------------------------------------------------------------------------------------
    cross apply 
    (
    Select -- remember we have for each single row (which have both file name)
           -- full restore is only generated from the oldest file .Bak
           -- the goal : Restore only once the database from full backup and restore remaining log backups
      StmtPartSeq=10, SqlStmtPartQ=Sep+Sql3
    From 
      (
      Select tmp=
      '
      Restore #RestoreTyp# #DestinationDatabase#
      from 
        disk="#SrcPath1#" 
      , disk="#SrcPath2#" 
      with norecovery
      '
      ) as Tmp
      CROSS APPLY (Select Sql0=Replace(tmp, '#RestoreTyp#', RestoreTyp) ) As Sql0
      CROSS APPLY (Select Sql1=Replace(Sql0, '#DestinationDatabase#', QuotedDestinationDatabase) ) As Sql1
      CROSS APPLY (Select Sql2=Replace(Sql1, '#SrcPath1#', SrcPath1 ) ) As Sql2
      CROSS APPLY (Select Sql3=Replace(Sql2, '#SrcPath2#', SrcPath2 ) ) As Sql3
      Cross Apply (Select Sep=IIF(seqSql>1, ';', '')) As Sep
    Where BackupTyp IN ('log', 'differential') Or (FirstCompleteBkpFile = SrcFile)
    UNION ALL 
    Select -- Move part of restore statement do apply only for restoring from full backup
      StmtPartSeq=20, SqlStmtPartQ=MovePart
    From 
      (
      Select TmpMovePart = 
  '      , move "#logicalName#" to "#physicalName#"'
      ) as TmpMovePart
      CROSS JOIN YourSqlDba.Maint.TemporaryBackupFileListInfo as F
      -- optional parameters to modify restore path by the mean of replaces
      Cross Apply (Select Path0=REPLACE (F.PhysicalName, pathRepFrom1, pathRepTo1)) as Path0
      Cross Apply (Select Path1=REPLACE (Path0, pathRepFrom2, pathRepTo2)) as Path1
      Cross Apply (Select Path=REPLACE (Path1, pathRepFrom3, pathRepTo3)) as Path
      Cross Apply (Select MovePart1=REPLACE(TmpMovePart, '#physicalName#', Path) ) as MovePart1
      Cross Apply (Select MovePart2=REPLACE(MovePart1, sourceDatabase, DestinationDatabase) ) as MoveTmpStopAtPrmPart2
      Cross Apply (Select MovePart3=REPLACE(MovePart2, '#logicalName#', F.LogicalName ) ) as MovePart3
      cross apply (Select MovePart=MovePart3) as MovePart
     -- move clause only add up to full restore and only for the first file encountered if there is 
     -- many full backup in the directory. We want to do full restore only once for the first file
     -- and get along with restoring from log backups only.
    Where FirstCompleteBkpFile = SrcFile And BackupTyp = 'database'
      And F.spid=@@SPID

    UNION ALL
    Select -- StopAt could be put for every file, but it is more elegant to put it only
           -- where stopAt time fall between previous end time and current end time 
      StmtPartSeq=25, SqlStmtPartQ=StopAtClause
    From
      (
      Select TmpStopAtPrm =
'       , STOPAT = "#StopAtPrm#";'        
      ) as TmpStopAtPrm
      CROSS APPLY (Select StopAtClause=REPLACE(TmpStopAtPrm, '#StopAtPrm#', StopAtPrm)) as StopAtClause
    Where -- make stopAt appears to the minimum place where it is meaningful, and not on a file
          -- later in time, which cause error.
      StopAtPrm Between EndBkpTimeOfPreviousFile And EndOfBkpFromFile 

    UNION ALL
    Select -- On the last file of the set of file to restore from, add restore database with recovery
      StmtPartSeq=30, SqlStmtPartQ=';Restore Database '+QuotedDestinationDatabase+ ' With Recovery'
    Where revSeqSql=1 -- last file is reached and restored by previous select, add recovery operation

    UNION ALL
    Select -- Adjust logical file name, if a system name is supplied, use this instead of the database name
      StmtPartSeq=40, SqlStmtPartQ=Sql
    From 
      YourSqlDba.Maint.TemporaryBackupFileListInfo as F
      CROSS APPLY (Select Tmp = ';Alter Database #DestinationDatabase# Modify File ( Name=#LogicalName#, NewName=#NewLogicalname# )') as Tmp
      CROSS APPLY (Select Sql0 = REPLACE(Tmp, '#DestinationDatabase#', QuotedDestinationDatabase)) as Sql0
      CROSS APPLY (Select Sql1 = REPLACE(Sql0, '#LogicalName#', F.LogicalName)) as Sql1
      -- Adjust logical file name, if a system name is supplied, use this instead if the database name is within, otherwise use 
      -- destination database (could be the same database or a new database)
      CROSS APPLY (Select NewLogicalName=REPLACE(F.LogicalName, sourceDatabase, ISNULL(systemName, DestinationDatabase))) as NewLogicalName
      CROSS APPLY (Select Sql = REPLACE(Sql1, '#NewLogicalName#', NewLogicalName)) as Sql
    Where LogicalName <> NewLogicalName -- si pas déjà selon meilleure pratique
      And F.spid=@@SPID
      And revSeqSql = 1 -- last file is reached and restored by previous select, and database is recovered, adjust logical name
    ) as SqlStmtPartQ

  CROSS APPLY 
  (
  -- for each row for which a restore statement part is produced, generate a print of this part
  Select PrintStmtSeq=1, SqlStmtPart='Print '''+Replace(SqlStmtPartQ Collate Database_default,'"','''''')+''''
  UNION ALL
  -- for each row for which a restore statement part is produced, replace " by a single quote
  -- using " is easier to code in sql template than '' and easy to replace once at the end
  Select PrintStmtSeq=2, SqlStmtPart=REPLACE(SqlStmtPartQ Collate Database_default, '"', '''')
  ) as PrintAndRunSeq
  -- order generated statement part by time, 
  -- if it is the print part of the statement parts or the statement part, 
  -- and by relative part order
  Order by EndOfBkpFromFile, PrintStmtSeq, StmtPartSeq

  Delete From YourSqlDba.Maint.TemporaryBackupHeaderInfo Where spid=@@SPID
  Delete From YourSqlDba.Maint.TemporaryBackupFileListInfo Where spid=@@SPID

End -- dbo.BuildRestoreFromBackupFiles
go

-- The procedure returns the generated RESTORE statements as a result set.
-- Review those statements carefully before copying and executing them.
Exec dbo.BuildRestoreFromBackupFiles
  @SourceFolder=N'P:\CommVaultRestore\Payroll'
, @DestinationDatabase=N'Payroll_RecoveryTest'
, @SystemName=N'Payroll'
, @pathRepFrom1=N'F:\Data\'
, @pathRepTo1=N'F:\Data\RecoveryTest\'
, @pathRepFrom2=N'L:\Data\'
, @pathRepTo2=N'L:\Data\RecoveryTest\'
, @pathRepFrom3=NULL
, @pathRepTo3=NULL
, @StopAt=N'2026-06-30 12:00:30';
