[int[]]$century = @(1..100);

Switch ($century)
{
    {($_ % 3 -eq 0) -and ($_ % 5 -eq 0)} {Write-Host "FizzBuzz"; continue}

    {($_ % 3 -eq 0)} {Write-Host "Fizz"}

    {($_ % 5 -eq 0)} {Write-Host "Buzz"}

    Default {$_} 
}