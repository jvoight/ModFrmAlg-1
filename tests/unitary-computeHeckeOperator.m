// Attach the appropriate specification file.
SetDebugOnError(true);
SetHelpUseExternalBrowser(false);

AttachSpec("spec");

// M := UnitaryModularFormTests();

Ts := [
    Matrix([
[ 5, 9, 7, 1, 0, 11, 7, 0, 11],
[ 5, 5, 5, 6, 3, 1, 8, 0, 11],
[ 4, 12, 1, 3, 10, 3, 7, 0, 9],
[ 2, 10, 1, 1, 2, 2, 2, 0, 2],
[ 0, 3, 1, 5, 1, 0, 5, 0, 7],
[ 2, 3, 2, 7, 10, 7, 6, 0, 11],
[ 5, 2, 2, 3, 0, 9, 7, 0, 2],
[11, 12, 5, 4, 12, 4, 12, 0, 11],
[ 5, 9, 2, 9, 1, 2, 11, 0, 1]
	      ]),
    Matrix([
[12, 4, 7, 8, 5, 10 , 1, 0, 11],
[ 8, 4, 12, 0, 3 , 1, 2, 0, 3],
[ 6, 0, 7, 10, 8, 6, 12, 0, 8],
[ 2, 11, 3, 7, 3, 2, 7, 0, 7],
[10, 3, 8, 4, 3, 2, 2, 0, 2],
[ 4, 4, 7, 12, 4, 2, 10, 0, 0],
[ 1, 2, 2, 6, 4, 9, 2, 0, 9],
[ 7, 8, 2, 0, 8 , 1, 6, 3, 7],
[ 5, 6, 7, 8, 4, 9, 0, 0, 8]
	      ]),
    Matrix([
[11, 3, 10, 10, 4, 3, 0, 0, 6],
[ 6, 5, 2, 12, 11, 2, 2, 0, 3],
[ 1, 11, 5, 11, 3, 6, 11, 0, 9],
[ 1, 4, 2, 5, 10, 11, 2, 0, 9],
[ 8, 11, 5, 8, 4, 5 , 1, 0, 2],
[ 0, 4, 2, 11, 2, 0, 7, 0, 11],
[12, 4, 11, 6, 10, 12, 0, 0 , 1],
[ 2, 4, 6, 6, 4, 12, 5, 0, 9],
[11, 6, 9, 9, 4 , 1, 11, 0, 2]
	      ]),
    Matrix([
[10, 3, 10, 3, 7, 10, 0, 0, 7],
[ 6, 3, 4, 2, 12, 5, 11, 0, 2],
[12, 4, 10, 11, 10, 0, 8, 0, 9],
[ 1, 8, 10, 10, 3, 0, 4, 0, 3],
[ 1, 12, 8, 5, 12 , 1, 12, 0, 11],
[ 0, 9, 4, 8, 11, 3, 8, 0, 2],
[ 1, 10, 0, 0, 2, 11, 3, 0, 12],
[ 9, 2, 6, 7, 2, 0, 7, 3, 8],
[ 2, 4, 3, 9, 9, 12, 2, 0 , 1]
	      ]),
    Matrix([
[ 1, 4, 3, 6, 5, 3, 2, 0, 11],
[ 8, 3, 10, 0, 3, 10, 0, 0, 5],
[11, 0 , 1, 5, 7, 9, 0, 0, 8],
[12, 7, 10 , 1, 5, 9, 12, 0, 5],
[10, 3, 9, 10, 2 , 1 , 1, 0, 4],
[ 8, 0, 12, 0, 2, 9, 12, 0, 3],
[12, 7, 9, 9, 2, 9, 9, 0, 4],
[11, 5, 6, 0, 5, 11, 0, 0, 9],
[ 5, 10, 5, 8, 8, 4, 3, 0, 3]
	      ]),
    Matrix([
[ 1, 6 , 1, 4, 9, 12, 7, 0, 11],
[12, 5, 10, 9, 5, 8, 11, 0, 12],
[ 3, 5, 5, 2, 12, 0, 11, 0, 0],
[ 4, 7, 8, 5, 2, 7, 2, 0, 10],
[ 5, 5 , 1, 6, 2, 11, 10, 0, 9],
[ 2, 9, 2, 11, 7, 3, 10, 0, 0],
[ 9, 3, 7, 0, 9, 5, 3, 0, 5],
[11 , 1, 8, 2 , 1 , 1, 11, 0, 6],
[ 5, 11, 10, 0, 5, 5, 0, 0, 12]
	      ]),
    Matrix([
[10 , 1, 6, 2, 4, 12, 10, 0, 4],
[ 2 , 1, 0, 10, 6, 5 , 1, 0, 5],
[ 8, 7, 0, 2, 9, 7, 11, 0, 0],
[11, 0, 7, 0, 5, 12, 0, 0, 4],
[ 8, 6, 9, 11, 11 , 1, 11, 0, 2],
[ 1, 2, 0, 11, 9, 11, 8, 0, 5],
[ 9, 10, 12, 7, 2, 6, 11, 0, 7],
[ 3, 5, 4, 12, 5, 7, 11, 3, 6],
[ 3, 10, 4, 0, 4, 7, 5, 0, 9]
	      ]),
    Matrix([
[ 5, 0, 12 , 1, 4, 11, 12, 0 , 1],
[ 0, 10, 2, 10, 10, 2, 4, 0, 2],
[ 4, 7, 3, 10, 2, 4, 8, 0, 11],
[ 9, 4 , 1, 3, 4 , 1 , 1, 0, 9],
[ 8, 10, 2 , 1, 6, 12, 7, 0, 11],
[ 9, 8 , 1, 8 , 1, 9, 4, 0, 5],
[ 5, 4 , 1, 4, 11, 5, 9, 0, 4],
[ 8, 5, 8, 4, 5, 4, 2, 0, 11],
[ 4, 4, 9, 11, 9, 4, 5, 0, 11]
	      ]),
    Matrix([
[ 5, 3, 5, 6, 0, 4, 6, 0, 3],
[ 6, 6, 11, 10 , 1 , 1, 2, 0, 8],
[11, 7, 6, 2, 0, 3, 10, 0, 12],
[ 7, 9, 2, 6, 4, 0, 10, 0, 11],
[ 0 , 1, 2, 0, 9, 0, 6, 0, 11],
[11, 4, 10, 10, 12, 8, 7, 0, 2],
[ 3, 2, 0, 3, 0, 5, 8, 0, 0],
[ 0, 7, 8, 6, 7, 8, 4, 3, 8],
[12, 3, 11, 12, 9, 0, 2, 0, 0]
	      ]),
    Matrix([
[12 , 1, 8, 2, 0, 6, 8, 0, 5],
[ 2, 2, 0, 7, 9, 10, 4, 0, 7],
[ 8 , 1, 7, 2, 3, 8, 7, 0, 10],
[ 6, 0, 5, 7, 7, 2, 2, 0, 3],
[ 0, 9, 10, 8, 3 , 1 , 1, 0, 8],
[ 6, 8, 2, 7, 2, 12, 4, 0, 4],
[11, 7, 2, 8, 2, 10, 12, 0, 2],
[ 0, 10, 2 , 1, 10 , 1, 10, 0, 11],
[ 7 , 1, 3, 10, 3, 2, 4, 0, 2]
	      ]),
    Matrix([
[ 0, 12, 8, 10, 11, 12, 10, 0, 7],
[11, 11, 6, 11, 12, 3, 5, 0 , 1],
[ 1, 9 , 1, 5 , 1, 0, 6, 0, 2],
[ 6, 12, 0 , 1, 10, 12, 6, 0, 0],
[ 9, 12, 5, 7, 12, 4, 8, 0, 2],
[ 1, 10, 6, 6, 3, 6, 3, 0, 3],
[ 9, 6, 12, 0, 8, 9, 6, 0, 5],
[ 0, 4 , 1, 10, 4 , 1, 5, 0, 4],
[ 2, 2, 0, 2, 4, 5, 3, 0, 2]
])];
