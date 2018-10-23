def lesser_of_two_evens(a,b):
    """
    Returns the lesser of two evens unless the user provides an odd value which would then return the odd value
    :param a:
    :param b:
    :return:
    """
    if a % 2 != 0:
        return a
    elif b % 2 != 0:
        return b
    elif a > b:
        return b
    else:
        return a


print(lesser_of_two_evens(2, 5))


def animal_crackers(a,b):
    """
    Checks to see if both user entered values start with the same letter
    :param a:
    :param b:
    :return:
    """
    return a[0] == b[0]


print(animal_crackers("Something", "Bally"))


def other_side_of_seven(num):
    """
    Given a user value return a value that is twice as far away on the other side of 7
    :param num:
    :return:
    """
    if num > 7:
        return 7-(num - 7)*2

    if num < 7:
        return (7 - num)*2 + 7


print(other_side_of_seven(5))


def old_macdonald(string):
    """
    Given a string caps the first and 4th letters
    :param string:
    :return:
    """
    if len(string) < 4:
        print('Name must be a least 4 characters long')
    else:
        word = ''
        list_word = list(string)
        for en, letter in enumerate(list_word):
            if en == 0 or en == 3:
                word = word + list_word[en].upper()
            else:
                word = word + list_word[en].lower()
        return word


print(old_macdonald('macdonald'))


def master_yoda(text):
    """
    Given a sentence by user, reverse the sentence
    :param text:
    :return:
    """
    split_text = text.split()
    split_text.reverse()
    final_sentence = ''
    for word in split_text:
        final_sentence = final_sentence + word + ' '
    return final_sentence


print(master_yoda("Are we Ready"))


def almost_there(n):
    """
    Given an integer n, return if n is within 10 of 100 or 200
    :param n:
    :return:
    """
    if n >= 111:
        return abs(n - 200) <= 10
    else:
        return abs(n-100) <=10


print(almost_there(190))


def has_33(nums):
    """
    Given a list ints will return True if the array contains a 3 next to a 3 positionally
    :param nums:
    :return:
    """
    found = False
    for en, num in enumerate(nums):
        if num == 3 and nums[en + 1] == 3:
            found = True
    return found


print(has_33([3, 3, 5, 6]))


def paper_doll(text):
    """
    Given a string return a string where for every character in the original there are three chracters
    :param text:
    :return:
    """
    list_text = list(text)
    word = ''
    for letter in list_text:
        word = word + letter * 3
    return word


print(paper_doll("This is a really long string"))


def blackjack(a, b, c):
    """
    Plays a game of blackjack with user entering in card numbers
    :param a:
    :param b:
    :param c:
    :return:
    """
    if a > 11 or b > 11 or c > 11:
        return "Card values cannot exceed 11"
    elif a + b + c > 21:
        return "BUST"
    else:
        return a + b + c


print(blackjack(10, 6, 7))


def rept(search_text, text):
    """
    Search for count of times text string appears with-in a text string
    :param search_text:
    :param text:
    :return:
    """
    found_counter = 0
    for en, letter in enumerate(text):
        if search_text == text[en:en+len(search_text)]:
            found_counter += 1
    return found_counter


print(rept("hah", "hahahah"))


def summer_69(arr):
    """
    Sum numbers in an array, ignore numbers in-between and including 6 and 9's return 0 for no numbers
    :param arr:
    :return:
    """
    current_sum = 0
    skip_till_9 = False
    for num in arr:
        if num == 6:
            skip_till_9 = True
        if not skip_till_9:
            current_sum += num
        if skip_till_9 and num == 9:
            skip_till_9 = False
    return current_sum


print(summer_69([4, 5, 6, 7, 8, 9]))


def spy_game(nums):
    """
    Takes a list of numbers and returns of that list has 007 in that order and sequence
    :param nums:
    :return:
    """
    double_o_seven = False
    for en, num in enumerate(nums):
        if num == 0 and nums[en + 1] == 0 and nums[en + 2] ==7:
            double_o_seven = True
    return double_o_seven


print(spy_game([1, 0, 2, 4, 0, ]))
