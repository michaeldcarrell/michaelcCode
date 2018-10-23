mylist = [element for element in 'hello']
print(mylist)

mylist = [numb for numb in range(0,11) if numb%2==0] #add conditionally functionallity
print(mylist)

mylist = [x if x%2==0 else 'ODD' for x in range(0,11)]#add else
print(mylist)
