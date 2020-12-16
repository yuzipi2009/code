#connect
#!/bin/pwsh
#update at 20201109: add ipv4 column

#Install-Module -Name VMware.PowerCLI -force
Get-Module -ListAvailable VMware.VimAutomation.Cis.Core|Import-Module

##ignore certification
Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -confirm:$false

$repository="/data/tools/repository/powershell"
$user=$(Get-Content "$repository/credential.txt").Split(",")[0]
$passwd=$(Get-Content "$repository/credential.txt").Split(",")[1]
Connect-VIServer -Server sin-vcenter2.ad.ea.com -Protocol https -User $user -Password $passwd

Write-Host "Start!!!!!!!!!!!!!!."

#################################
$header = @"
<style>

      span {
        color: #2196F3;
      }


      h1 {

          font-family: Arial, Helvetica, sans-serif;
          color: #CC0000;
          font-size: 30px;
          text-align:center;

      }


      h2 {

          font-family: Arial, Helvetica, sans-serif;
          color: #18b783;
          font-size: 29px;
          text-align:center;
          #text-decoration:underline;

      }

      h3 {

          font-family: Arial, Helvetica, sans-serif;
          color: #000099;
          font-size: 20px;
          font-weight: normal;
          text-align:center;
          #text-decoration:underline;

      }


      table {
         font-size: 16px;
         border: 0px;
         font-family: Arial, Helvetica, sans-serif;
         text-align: center;
         margin-left: auto;margin-right: auto;
       }

      td {
         padding: 4px;
         margin: 0px;
          border: 0;
        }

      th {
         background: #395870;
         background: linear-gradient(#49708f, #293f50);
         color: #fff;
         font-size: 11px;
         text-transform: uppercase;
         padding: 10px 15px;
         vertical-align: middle;
         }

      tbody tr:nth-child(even) {
          background: #f0f0f2;
      }


     #CreationDate {
          font-family: Arial, Helvetica, sans-serif;
          color: #0e0e0e;
          font-size: 16px;
          margin-left: 30px

     }


     .poweroff {
          color: #ff0000;
     }


     .poweron {

          color: #008000;
     }

  </style>
"@

#get-vm

function count_object ($source,$object,$keyword_list){
    $objects_number_map=@{}

    foreach($item in $keyword_list ){
        #Write-Host "item is $item"
        $item_count=($source|Select-Object $object|Where-Object{$_ -like "*$item*"}|Measure-Object).Count
        $objects_number_map."the number of $item is:  "=$item_count
    }
    return $objects_number_map
}

$summary=@()
#the loop below is to get "$summary"
foreach ($vm in get-vm|Where-Object{$_.Name -like "*dre*" -or $_.Name -like "*build*" -and $_.VMHost -notlike "*eamel*"}){
    $sha_vm=""|Select-Object Vmname,PowerStat,OS,Memory_GB,CPU_NUM,Storage,Storage_Usage,IPv4
    $sha_vm.Vmname=$vm.name
    $sha_vm.Powerstat=$vm.PowerState
    $sha_vm.OS=$vm.Guest.OSFullName
    $sha_vm.Memory_GB=$vm.MemoryGB
    $sha_vm.CPU_NUM=$vm.NumCpu
    $sha_vm.IPv4=($vm.Guest.ipaddress)[0]
    #ignore the server with "PoweredOff" stat
    if ($sha_vm.Powerstat -eq "PoweredOff" -or -not $sha_vm.OS){
        $sha_vm.Storage="NA"
        $sha_vm.Storage_Usage="NA"
    }
    else
    {
        $servers_after_ignore=$vm.Extensiondata.Guest.Disk|Where-Object{$_.diskpath -notlike "*boot*" -and $_.diskpath -notlike "*tmp*" -and $_.diskpath -notlike "*var*"}
        $sha_vm.Storage=$servers_after_ignore|foreach-object{$_.diskpath + ": " + [math]::round($_.capacity/1048576/1024,0) + "GB" + "PLACEHOLDER"}|Out-String
        $sha_vm.Storage_Usage=$servers_after_ignore|foreach-object{$_.diskpath + ": " + [math]::round(($_.Capacity - $_.FreeSpace)*100/$_.Capacity,1) + "%" + "PLACEHOLDER"}|Out-String
    }
    #($vm|Get-hardDisk|Select-Object @{Name="foo";Expression={$_.Name + "(" + $_.capacityGB + ")"}}|Select-Object -ExpandProperty foo|Out-String).Replace(" ","_").Replace('Hard_','')
    #$summary will have all information of sha and mc after the loop!
    $summary+=$sha_vm
}
#$summary
#filter $summary to get eash and eamc
$sh_eash=$summary|Where-Object {$_.vmname -like "*eash*"}
$sh_eamc=$summary|Where-Object {$_.vmname -like "*eamc*"}

#count the number of os type and of studios eash and eamc
$os_type=$("Windows","Centos","Ubuntu")

#studio eash
$os_type_count_eash=count_object $sh_eash "os" $os_type
#studio eamc
$os_type_count_eamc=count_object $sh_eamc "os" $os_type


#below is to create the Fragment(div) used for html
$os_type_count_eash=New-Object psobject -Property $os_type_count_eash|ConvertTo-Html -As List -Fragment -PreContent "<h3>OS Summary</h3>"
$os_type_count_eamc=New-Object psobject -Property $os_type_count_eamc|ConvertTo-Html -As List -Fragment -PreContent "<h3>OS Summary</h3>"


$summary_eash=($summary|Where-Object{$_.vmname -like "*eash*"}|Sort-Object vmname|ConvertTo-Html -Fragment -PreContent "<h3>Vm details of EASH</h3>").replace('<td>PoweredOn</td>','<td class="poweron">PoweredOn</td>').replace('<td>PoweredOff</td>','<td class="poweroff">PoweredOff</td>').Replace('PLACEHOLDER','<br>')

$mac_refer='<h4 align = middle>Click <a href="./mac.html"><span>here</span></a> find details of mac servers</h4>'

$summary_eamc=($summary|Where-Object{$_.vmname -like "*eamc*"}|Sort-Object vmname|ConvertTo-Html -Fragment -PreContent "<h3>Vm details of EA China</h3>").replace('<td>PoweredOn</td>','<td class="poweron">PoweredOn</td>').replace('<td>PoweredOff</td>','<td class="poweroff">PoweredOff</td>').Replace('PLACEHOLDER','<br>')


$vcenter="<h1>Vcenter: sin-vcenter2.ad.ea.com</h1>"
$studio_eash="<h2>Studio: EA Create ShangHai(EASH)</h2>"
$studio_eamc="<h2>Studio: EA CHINA(Popcap)</h2>"
$update="<p id='CreationDate'>Update at: $(Get-Date)(CST)</p> "

ConvertTo-Html -Body "$update $vcenter $studio_eash $os_type_count_eash $summary_eash $studio_eamc $os_type_count_eamc $mac_refer $summary_eamc" -Head $header -Title "Shanghai Dre vm summary"|Out-File sha_vm.html

Write-Host "Script run complete."

#deal with mac part
(import-csv .\mac_list.csv|ConvertTo-Html -Body "$update"-Head $header).Replace('PLACEHOLDER','<br>')|out-file mac.html


Write-Host "mac part complete."

#$ssh_root_pw=$(Get-Content "$repository/credential.txt").Split(",")[2]
#$remote_nginx_home="/usr/share/nginx/html"
#pscp -pw $ssh_root_pw -P 22 sha_vm.html root@10.88.230.70:$remote_nginx_home
#sshpass -p $ssh_root_pw scp -r -o StrictHostKeyChecking=no sha_vm.html root@10.88.230.70:$remote_nginx_home
