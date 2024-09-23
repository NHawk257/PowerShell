#Not strictly Exchange Related but sometimes you need to get all your SPF records for 20+ domains in one place to verify stuff like letting a block of IPv4 addresses go

$Domains = import-csv .\Domains.csv
$csvfilename = ".\SPF-Report_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Values"

Foreach ($D in $Domains){

    try {
        $Records = Resolve-DnsName -Name $D.Name -Type TXT -ErrorAction Stop,SilentlyContinue | Where-Object {$_.Strings -like "*spf1*"} 
        If (($Records).count -gt 1){
                Write-Host $D.Name "has more than 1 SPF record, this is not allowed" -BackgroundColor Red -ForegroundColor Black
        }
        Else {
        $CleanRecords = $Records | Select-Object Name,@{Name='Records';Expression={[string]::join(";",($_.Strings))}}
        Add-Content -Path $csvfilename -Value $CleanRecords 
        }
    }
    catch {
        Write-Host $D.Name "is not a valid domain or does not have an SPF record configured, please check manually" -ForegroundColor Yellow
    }
}