import sys
import csv

# declare variables
operator = str(sys.argv[1])
frametimes = []

def add():
    num1 = float(sys.argv[2])
    num2 = float(sys.argv[3])
    sum = num1 + num2
    print(sum)
def div():
    num1 = float(sys.argv[2])
    num2 = float(sys.argv[3])
    sum = num1/num2
    print(sum)
def divint():
    num1 = int(sys.argv[2])
    num2 = int(sys.argv[3])
    sum = num1/num2
    print(int(sum))
def rnd():
    num1 = float(sys.argv[2])
    res = int(round(num1, 1))
    print(res)
# Credit to Bored and AMIT
def get_lows(value):
    current_total = 0.0
    for present in frametimes:
        current_total += present
        if current_total >= value / 100 * benchmark_time:
            return 1000 / present

if operator == 'add': 
    add()
if operator == 'div': 
    div()
if operator == 'divint': 
    divint()
if operator == 'rnd': 
    rnd()
if operator == 'parse': 
    # Credit to Bored and AMIT
    with open(sys.argv[2], 'r') as f:
        for row in csv.DictReader(f):
            frametimes.append(float(row['MsBetweenPresents']))
    frametimes = sorted(frametimes, reverse=True)
    benchmark_time = sum(frametimes)
    print(round(get_lows(0.01), 1))