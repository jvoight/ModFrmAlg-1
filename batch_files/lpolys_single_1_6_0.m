AttachSpec("spec");
import "tests/tests.m" : get_lpolys;
time0 := Cputime();
get_lpolys(1, [6, 0]);
printf "elapsed: %o\n", Cputime()-time0;
exit;
