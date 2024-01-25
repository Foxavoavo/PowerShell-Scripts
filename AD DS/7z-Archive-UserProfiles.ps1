<#
I use this batch to archive user profiles on a file server
you need to install 7z on the file server and ru nthe batch locally.

*create the folders/ rename the folders before running the batch. 
#>
Add-Content "C:\scripts\archiver\User01_results.csv" "UserName, SAMAccountName, ArchivedOkay, SourcePath, Archivedfile"
$results = "C:\scripts\archiver\User01_results.csv"
#Import data here
$thecsv = import-csv "C:\scripts\archiver\User01_TheFoldersToArchive.csv"
#Errors here
Add-Content "C:\scripts\archiver\User01_Errors.csv" "FolderSource, Notes"
$ERresults = "C:\scripts\archiver\User01_Errors.csv"
$TimeOut = Start-Sleep -s 1
#Here the loop starts
Foreach ($arch in $thecsv) {
    $UName = $arch.Name
    $SAMU = $arch.SAMAccountName
    $FullName = $arch.FolderPath
    $arch = "ARCHIVED_"
    $archive1 = $arch + $SAMU
    try { 
        $TimeOut
        & "C:\Program Files\7-Zip\7z.exe" a -sdel D:\Leavers_Archive\Archive\$archive1.7z $FullName | Out-Null
        $TimeOut
        Add-Content $results "$UName, $SAMU, YES, $source1, D:\Leavers_Archive\Archive\$archive1.7z"
        write-host "------------------------------------------------$archive1 created okay from $UName--------------------------------------------------"
    }
    catch {
        Add-Content $ERresults "$FullName, Unable to Archive double check this folder"
        Write-Host "Error running archiver for $UName"
    }
}