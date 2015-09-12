2.midiratio
9/8
10/9
161/144

exp((log(9/8)+log(10/9))/2)

~partials=(2..100).select({ |x| (x % 2 == 0) || (x % 3 == 0) || (x % 5 == 0) && (x % 9 > 0)})