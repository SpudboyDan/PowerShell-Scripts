# Simple demonstration of a list of motorcycles
motorcycles = ['honda', 'yamaha', 'suzuki']
print(motorcycles)

# Replacing index 0 with "ducati"
motorcycles[0] = 'ducati'
print(motorcycles)

motorcycles = ['honda', 'yamaha', 'suzuki']
print(motorcycles)

# Appending the list with "ducati"
motorcycles.append('ducati')
print(motorcycles)

# Initializing an empty list and adding to it with the append method
motorcycles = []
print(motorcycles)
motorcycles.append('honda')
motorcycles.append('yamaha')
motorcycles.append('suzuki')

print(motorcycles)

# Inserting the value "ducati" to the list at index 0
motorcycles.insert(0, 'ducati')
print(motorcycles)

# Using the delete statement on index 0
motorcycles = ['honda', 'yamaha', 'suzuki']
print(motorcycles)
del motorcycles[0]
print(motorcycles)

motorcycles = ['honda', 'yamaha', 'suzuki']
print(motorcycles)

# Popping the last list item and printing it out
popped_motorcycle = motorcycles.pop()
print(motorcycles)
print(popped_motorcycle)

# Popping the last list item and printing it inside an f string
motorcycles = ['honda', 'yamaha', 'suzuki']
last_owned = motorcycles.pop()
print(f"The last motorcycle I owned was a {last_owned.title()}.")

# Popping the first list item and printing it inside an f string
motorcycles = ['honda', 'yamaha', 'suzuki']
first_owned = motorcycles.pop(0)
print(f"The first motorcycle I owned was a {first_owned.title()}.")

# Using the remove method on a list item we know the name of
motorcycles = ['honda', 'yamaha', 'suzuki', 'ducati']
print(motorcycles)
motorcycles.remove('ducati')
print(motorcycles)

# Assigning a list item to a variable and removing it from the list
motorcycles = ['honda', 'yamaha', 'suzuki', 'ducati']
print(motorcycles)

too_expensive = 'ducati'
motorcycles.remove(too_expensive)
print(motorcycles)
print(f"\nA {too_expensive.title()} is too expensive for me.")
