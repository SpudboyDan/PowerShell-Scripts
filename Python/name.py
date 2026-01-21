name = "Ada Lovelace"
print(name.title())
print(name.upper())
print(name.lower())

first_name = "ada"
last_name = "lovelace"

# This is an f-string. f stands for "format"
full_name = f"{first_name} {last_name}"
print(full_name)
print(f"Hello, {full_name.title()}!")
message = f"Hello, {full_name.title()}!"
print(message)

# The \n and \t operators are useful for formatting text
print("Languages:\n\tPython\n\tC\n\tJavaScript")
