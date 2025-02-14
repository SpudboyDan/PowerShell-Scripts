[int[]]$century = @(1..100);

foreach ($integer in $century)

{
    if ((($integer % 3) -eq 0) -and (($integer % 5) -eq 0))
    {Write-Host "FizzBuzz"}

    elseif (($integer % 3) -eq 0)
    {Write-Host "Fizz"}

    elseif (($integer % 5) -eq 0)
    {Write-Host "Buzz"}

    else
    {Write-Host $integer}
}