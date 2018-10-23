with open('somefile.txt', mode = 'w') as f:
    f.write("I wrote to this file")

with open('somefile.txt', mode='a') as f:
    f.write("\nI added to this file")

with open('somefile.txt', mode='r') as f:
    print(f.read())

with open('somefile.txt', mode='w+') as f:
    f.write('This overwrites then reads the file')

with open('somefile.txt', mode='r+') as f:
    print(f.read())
