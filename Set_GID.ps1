######################################################################
# UNIX Attributes Editing and Function
# We need to set gidNumber, loginShell, unixHomeDirectory, uid, uidNumber, msSFU30NisDomain
$rc = $?

# Sometimes this seems to timeout, do not set anything if that's the case
If ($rc -ne $True)
{
    write-host "User lookup failed with code $rc, aborting..."
    exit $False
}

# For safety, let's make sure $UserName is actually the user we want ### Needs work
# If ($UserName.sAMAccountName -ne $UserName)
#{
    #write-host "User appears empty, something went wrong"
    #exit $False
#}

# If the msSFU30NisDomain is not set, set it
If ($UserName.msSFU30NisDomain -eq $null)
{
    write-host "Setting domain to smnet"
    Set-ADUser -Identity $UserName -Replace @{ msSFU30NisDomain = "smnet" }
}

# If the loginShell is not set, set it
If ($UserName.loginShell -eq $null)
{
    write-host "Setting login shell to /bin/bash"
    Set-ADUser -Identity $UserName -Replace @{ loginShell = "/bin/bash" }
}

# If the unixHomeDirectory is not set, set it
If ($UserName.unixHomeDirectory -eq $null)
{
    write-host "Setting homedir domain to /home/$UserName"
    Set-ADUser -Identity $UserName -Replace @{ unixHomeDirectory = "/home/"+"$UserName" }
}

# If the uid is not set, set it
#If ($UserName.uid -eq $null -or [string]$UserName.uid -eq "") REDUNDANT SAFETY STEP, done below. To be removed.
{
    write-host "Setting uid to $($UserName.sAMAccountName)"
    Set-ADUser -Identity $UserName -Replace @{ uid = "$($UserName.sAMAccountName)" }
}

# If the gidNumber is not set, set it
$GID = Get-ADGroup $Department -Properties * | Select gidNumber
If ($UserName.gidNumber -eq $null)
{
    write-host "Setting gidNumber to AD Primary Group"
    Set-ADUser -Identity $UserName -Replace @{ gidNumber = "$($GID.gidNumber)" }
}

# If the uidNumber is not set, set it
If ($user.uidNumber -eq $null)
{
    # Get next available uidNumber
    # Pick a known low starting point
    $low  = 10000
    $high = 18000
    $highestuser = Get-AdUser -Filter { uidNumber -gt $low -and uidNumber -lt $high } -Properties uidNumber | Sort-Object -Property uidNumber -Descending | select-object -first 1
    If ($? -ne $True)
    {
        write-host "Calculating next UID failed on AD lookup, aborting"
        exit
    }
    $nextuid = $highestuser.uidNumber + 1
    write-host "Setting uidNumber to $nextuid"
    Set-ADUser -Identity $UserName -Replace @{ uidNumber = $nextuid }
}