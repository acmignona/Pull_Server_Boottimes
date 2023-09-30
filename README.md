# Description: 
This PowerShell script has been crafted to facilitate the retrieval of server information, specifically boot time, from servers identified in a referenced CSV file. It adheres to a systematic approach, utilizing of the most efficient method first, namely, Get-Ciminstance. In the event of an unsuccessful attempt, it explores alternative methods such as invoking commands, leveraging Get-Computerinfo, and, if necessary, resorting to systeminfo. The incorporation of multiple methods serves the purpose of overcoming potential obstacles such as firewall or network controls that may impede the script's functionality, particularly in environments where servers span diverse subnetworks, each governed by distinct firewall rules.

# Important: 
You must define the following variables within the script to your needs: 
$referencefile & $export_location 
