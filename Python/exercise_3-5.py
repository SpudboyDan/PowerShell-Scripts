guests = ['sean combs', 'albert einstein', 'jeffrey epstein']
print(f"Greetings {guests[0].title()}, please come to dinner diddy blud.")
print(f"Hello diddy blud on the calculator, please come to dinner {guests[1].title()}.")
print(f"Hello evil man {guests[2].title()}, would you please join me for dinner?")

absent_guest = guests.pop()
print(f"\nLooks like evil man {absent_guest.title()} can't make it for dinner tonight.")

guests.append('bill clinton')
print(f"\nPlease come to dinner {guests[0].title()} diddy blud.")
print(f"You're still welcome to come to dinner on the calculator {guests[1].title()}.")
print(f"Hello Mr. President {guests[2].title()}, please join us for dinner.")
