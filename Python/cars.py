cars = ['bmw', 'audi', 'toyota', 'subaru']
cars.sort()
print(f"\n{cars}")

cars.sort(reverse=True)
print(f"\n{cars}")

cars = ['bmw', 'audi', 'toyota', 'subaru']
print("\nHere is the original list:")
print(cars)

print("\nHere is the sorted list:")
print(sorted(cars))

print("\nHere is the original list again:")
print(cars)

cars.reverse()
print(f"\n{cars}")

print(len(cars))
