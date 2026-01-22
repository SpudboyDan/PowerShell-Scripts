guests = ['sean combs', 'albert einstein', 'jeffrey epstein']
print(f"Greetings {guests[0].title()}, please come to dinner diddy blud.")
print(f"Hello diddy blud on the calculator, please come to dinner {guests[1].title()}.")
print(f"Hello evil man {guests[2].title()}, would you please join me for dinner?")

print(f"\nLooks like evil man {guests[2].title()} can't make it for dinner tonight.")
guests[2] = 'bill clinton'

print(f"\nPlease come to dinner {guests[0].title()} diddy blud.")
print(f"You're still welcome to come to dinner on the calculator {guests[1].title()}.")
print(f"Hello Mr. President {guests[2].title()}, please join us for dinner.")

print("\nYooooo I just found a bigger table for dinner tonight my diddy bluds.")
guests.insert(0, 'hillary clinton')
guests.insert(2, 'barack obama')
guests.append('hulk hogan')

print(f"\nMiss first lady, you should come to dinner {guests[0].title()}.")
print(f"Mr. Diddy Blud {guests[1].title()} please join us for dinner.")
print(f"Yooooooooo Mr. President {guests[2].title()} please join us for dinner time.")
print(f"Hello also Mr. Calculator {guests[3].title()}, join us for dinner.")
print(f"Yooooooo if it isn't the diddy blud president, join us for dinner Mr. {guests[4].title()}.")
print(f"It's the hulkster himself! Welcome to dinner Mr. {guests[5].title()}.")

print("\nBad news everybody. I can only invite two people for dinner.")

hulkster_guest = guests.pop()
print(f"\nSorry hulkster {hulkster_guest.title()}, you are no longer invited to dinner") 

bill_guest = guests.pop()
print(f"\nSorry Mr. Diddy President {bill_guest.title()}, you are no longer invited to dinner")

calculator_guest = guests.pop()
print(f"\nSorry Mr. Calculator {calculator_guest.title()}, you are no longer invited to dinner")

obama_guest = guests.pop()
print(f"\nSorry Mr. War Crime {obama_guest.title()}, you are no longer invited to dinner")

print(f"\nYou're still invited to dinner Mr. Diddy Blud {guests[1].title()}.")
print(f"\nYou're still invited to dinner Miss First Lady {guests[0].title()}.")

del guests[1]
del guests[0]
print(f"\n{guests}")
