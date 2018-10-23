Condition = True

if Condition == True: #The condition in this example could actually just be Condition as it is already a boolean value
    print('Condition is True')
else:
    print('Condition is False')

loc = 'Somewhere'

if loc =='Auto Shop':
    print(f'At {loc}')
elif loc == 'Bank':
    print(f'At {loc}')
else:
    print(f'Unknown location ({loc}) entered. We dont know where you are!')

my_iterable = [1,2,3]
for item_name in my_iterable:
    print(item_name)

#In conditions where the loop length is known AND a counting variable is not needed the following syntax can be used
for _ in range(1,5): #<-This only prints 4 times because it goes from range 1 UP TO range 5 meaning that does not run a 5th time
    print("Cool!")

#Tuple unpacking
for a,b in [(1,2),(3,4),(5,6)]:
    print(a)
    print(b)

#for loops in dictionaries
for item in {'k1':1,'k2':2,'k3':3}: #Only Lists Keys
    print(item)

for item in {'k1':1,'k2':2,'k3':3}.items(): #Lists Keys and Values
    print(item)

for key,value in {'k1':1,'k2':2,'k3':3}.items(): #Use Tuple unpacking to look at either
    print(value)

x = 0
while x<5:
    print(f'The current value of x is {x}')
    x += 1 #Same as x = x + 1

#Pass, Break and Continue
for i in range(1,5):
    pass #Lets the loop exist with no error

for letter in 'Sammy':
    if letter =='a':#lets Python check if a letter is a and if it is it goes onto the next loop without printing the letter
        continue
    print(letter)

#Break same break as R

for index, letter in enumerate('abcde'):# Enumerate allows one to index a range as it itterates over it without having to create a counter
    print(f'Letter is {letter}, Index is {index}')

for item in zip([1,2,3], ['a', 'b', 'c']): #zipping two lists together will create an iterable object which python will pack into tuples
    print(item)

for item in zip([1,2,3,4,5,6], ['a', 'b', 'c']):#zip will only pack as far as the shortest zipped element
    print(item)

print('x' in ['a', 'b', 'x'])
