languages = ['spanish', 'french', 'japanese', 'german', 'korean', 'chinese']
languages[0] = 'english'
print(languages)

languages.append('spanish')
print(f"\n{languages}")

languages.insert(0, 'italian')
print(f"\n{languages}")

del languages[1]
print(f"\n{languages}")

popped_language = languages.pop()
print(f"\n{popped_language}")

languages.remove('german')
print(f"\n{languages}")

print(f"\n{sorted(languages)}")
print(f"\n{languages}")
print(f"\n{sorted(languages, reverse=True)}")
print(f"\n{languages}")

languages.sort()
print(f"\n{languages}")

languages.sort(reverse=True)
print(f"\n{languages}")

print(f"\nThere are {len(languages)} languages in my list")

languages = ['spanish', 'french', 'japanese', 'german', 'korean', 'chinese']

languages.reverse()
print(f"\n{languages}")
