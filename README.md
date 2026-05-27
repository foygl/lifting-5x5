# Lifting 5x5

This is a quick and dirty script that I wrote for me and my partner to track our progress on the StrongLifts 5x5 program (not affiliated).

One of the **killer features** is a "buddy mode" plate calculator, that makes it easier to share equipment and interleave your workouts even if you are progressing at different rates.

The main reason I threw this together is that didn't want to pay an app subscription for something that is just a glorified calculator.

I kept it as core Ruby with no external dependencies, so it should be trivial to run on any machine with Ruby installed (on Linux or Mac at least).

## Tips

- You can do some advanced configuration by editing json files. You should read the code to find out more!
- You probably want to back up the contents of `db` somewhere.

## Disclaimers

- There may be bugs! (I will fix them as I find them)
- It may be incomplete or more complex to use as you advance on the program
- Where testing exists it is pretty basic and in no way covers all edge cases
- This script is really a prototype for an app that I may never build!
