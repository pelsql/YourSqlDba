# Run with PowerShell 7: .\Test-ClrGetFolderListDetailed.ps1
# Compiles the repository's C# method in memory; no SQL Server connection.
$ErrorActionPreference = 'Stop'

$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'YourSQLDba_InstallOrUpdateScript.sql'))
$methodStart = $source.IndexOf('public static IEnumerable Clr_GetFolderListDetailed(string', [StringComparison]::Ordinal)
if ($methodStart -lt 0) { throw 'CLR method not found in the installation script.' }
$methodEnd = $source.IndexOf('// method defined for the above function', $methodStart, [StringComparison]::Ordinal)
if ($methodEnd -lt 0) { throw 'End of CLR method not found.' }
$method = $source.Substring($methodStart, $methodEnd - $methodStart)
$details = [regex]::Match($source, '(?s)struct FileDetails \{.*?\}')
if (-not $details.Success) { throw 'FileDetails structure not found.' }

# Replace only enumeration: the test hook really enumerates the directory,
# then deletes B.bak before returning the captured list to the original loop.
$enumeration = 'System.IO.Directory.GetFiles(FolderPath, SearchPattern)'
if ([regex]::Matches($method, [regex]::Escape($enumeration)).Count -ne 1) {
    throw 'Expected exactly one directory enumeration call.'
}
$testMethod = $method.Replace($enumeration, 'EnumerateThenDelete(FolderPath, SearchPattern)')
$testNamespace = 'FolderListTest_' + [guid]::NewGuid().ToString('N')
$hook = @'
    public static string DeletedFile;
    public static string[] EnumeratedFiles;

    private static string[] EnumerateThenDelete(string folder, string pattern)
    {
        string[] files = Directory.GetFiles(folder, pattern);
        Array.Sort(files, StringComparer.Ordinal);
        EnumeratedFiles = files;
        DeletedFile = Path.Combine(folder, "B.bak");
        if (Array.IndexOf(files, DeletedFile) < 0)
            throw new Exception("B.bak was not enumerated before deletion.");
        File.Delete(DeletedFile);
        return files;
    }
'@
$code = "using System; using System.IO; using System.Collections; namespace $testNamespace { public " +
    $details.Value + ' public class Harness { ' + $hook + $testMethod + ' } }'
Add-Type -TypeDefinition $code
$harness = ($testNamespace + '.Harness') -as [type]

$testFolder = Join-Path ([IO.Path]::GetTempPath()) ('YourSqlDba-ClrTest-' + [guid]::NewGuid().ToString('N'))
$testFiles = @('A.bak', 'B.bak', 'C.bak') | ForEach-Object { Join-Path $testFolder $_ }
[IO.Directory]::CreateDirectory($testFolder) | Out-Null
try {
    foreach ($file in $testFiles) { [IO.File]::WriteAllText($file, 'CLR metadata test') }
    $rows = @($harness::Clr_GetFolderListDetailed($testFolder, '*.bak'))

    if ($harness::EnumeratedFiles.Count -ne 3) { throw 'Expected three enumerated files.' }
    if ([IO.File]::Exists($harness::DeletedFile)) { throw 'B.bak still exists.' }
    if ($rows.Count -ne 3) { throw 'Expected three returned rows, including the failed file.' }
    if ($rows[0].FileName -ne 'A.bak' -or $rows[0].ErrMessage) { throw 'A.bak was not read successfully.' }
    if ($rows[1].FileName -ne 'B.bak' -or [string]::IsNullOrWhiteSpace($rows[1].ErrMessage)) {
        throw 'B.bak must retain its name and report an error.'
    }
    if ($rows[2].FileName -ne 'C.bak' -or $rows[2].ErrMessage) { throw 'Processing did not continue successfully to C.bak.' }
    foreach ($row in $rows) {
        $null = [System.Data.SqlTypes.SqlDateTime]::new($row.ModifiedDate)
        $null = [System.Data.SqlTypes.SqlDateTime]::new($row.CreatedDate)
    }

    $rows | Select-Object FileName, FileSizeByte, ErrMessage | Format-Table -AutoSize -Wrap
    Write-Output 'PASS: B.bak was enumerated, then deleted; its error was retained and C.bak was still processed.'
}
finally {
    # Delete only the three explicitly created files and the empty test folder.
    foreach ($file in $testFiles) {
        if ([IO.File]::Exists($file)) { [IO.File]::Delete($file) }
    }
    [IO.Directory]::Delete($testFolder, $false)
}
