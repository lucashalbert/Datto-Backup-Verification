<#
.SYNOPSIS
  Script designed to check if a process is running withing a specified timeout period.

.DESCRIPTION
  Uses the Get-Process cmdlet along with a timeout mechanism to check if a process is running within a certain amount of time.

  The $processName variable must be set to the short name of the process.
  This value is usually the full name of the executable minus the '.exe' file extension.
  It can also be found in the 'ProcessName' column of the Get-process PowerShell command's output.

.INPUTS
  processName [optional] 

.OUTPUTS
  Console output and Exit Code

.NOTES
  Author:         Lucas Halbert <contactme@lhalbert.xyz>
  Version:        2020.09.28
  Date Written:   09/28/2020
  Date Modified:  09/28/2020

  Revisions:      2020.09.28 - Inital draft

.EXAMPLE
  .\checkProcess.ps1

.LICENSE
  License:        BSD 3-Clause License

  Copyright (c) 2020, Lucas Halbert
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and#or other materials provided with the distribution.

  * Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

# Gather paramters
param(
    [Parameter(Mandatory=$false)][string]$processName
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------#
# Initialize system.timeoutException exception object
$timeoutException = new-object system.timeoutException


#----------------------------------------------------------[Declarations]----------------------------------------------------------#
# Declare Process Name
if($processName -eq $null -or $processName -eq "")
{
    $processName = 'slack'
}

# Declare timeout in seconds
$timeout = '60'      ## seconds

# Declare retry interval in seconds
$retryInterval = '1' ## seconds

# Declare condition script codeblock
$condition1 = { (Get-Process $processName -ErrorAction SilentlyContinue).count -lt 1 }

# Declare the default result
$result = $FALSE


#-----------------------------------------------------------[Execution]------------------------------------------------------------#
# Start the timer
$timer = [Diagnostics.Stopwatch]::StartNew()

Try
{
    while (($timer.Elapsed.TotalSeconds -lt $timeout) -and (& $condition1)) {
        # Sleep for retryInterval
        Start-Sleep -Seconds $retryInterval

        # Get total elapsed time
        $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
        
        Write-Host "Still waiting for process '$processName' to be running after [$totalSecs] seconds..."
    }
    
    Write-Host "Process info: $process"

    # Stop the timer
    $timer.Stop()

    # Check if timer elapsed time has exceeded the defined timeout
    if ($timer.Elapsed.TotalSeconds -gt $timeout)
    {
        # Throw exception
        throw $timeoutException
    }
    else
    {
        Write-Verbose -Message "$process"
        $result = $TRUE
    }
    
}
Catch [system.timeoutException]
{
    Write-Host "FAIL: Timed out while waiting for process '$processName' to be in a 'running' state."
}
Catch
{ 
    Write-Host "FAIL: Caught an unexpected exception while waiting for process '$processName' to be in a 'running' state: $_.Exception.Message"
}

Finally
{  
    If ($result)
    {        
        Write-Host "SUCCESS: '$processName' is 'running'"
        Exit 0
    }
    Else
    {   
        Exit 1
    }
}