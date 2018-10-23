def name_fuction(name='NAME'):
    '''


    '''
    return 'Hello ' + name


result = name_fuction()
print(result)


def myfunc(*args):
    """
    allows users to pass through an invinate number of arguments and adds all into a tuple
    :param args:
    :return:
    """
    return sum(args) * 0.05


print(myfunc(2,20,50))


def myfunc(**kwargs):
    """
    This function looks for the key 'fruit' entered by user to orient itself
    :param kwargs:
    :return:
    """
    if 'fruit' in kwargs:
        print('My fruit of choice is {}'.format(kwargs['fruit']))
    else:
        print('I did not find any fruit here')


myfunc(fruit='apple', veggie='lettuce')

def myfunc(*args, **kwargs):
    """
    This function allows for both the use of infinite number of args and infinite number of kwargs
    :param args:
    :param kwargs:
    :return:
    """
    print('I would like {} {}'.format(args[0], kwargs['food']))


myfunc(100, 50, 75, fruit='orange', food='eggs')
