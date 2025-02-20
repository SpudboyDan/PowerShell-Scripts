[int[]]$century = @(1..100);

foreach ($integer in $century)

{
    if ([System.Math]::IEEERemainder($integer, 15) -eq 0)
    {Write-Host "FizzBuzz"}

    elseif ([System.Math]::IEEERemainder($integer, 3) -eq 0)
    {Write-Host "Fizz"}

    elseif ([System.Math]::IEEERemainder($integer, 5) -eq 0)
    {Write-Host "Buzz"}

    else
    {Write-Host $integer}
}