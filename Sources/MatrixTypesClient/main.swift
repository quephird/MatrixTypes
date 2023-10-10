import MatrixTypes

@expandMatrixType(order: 2)
public struct Matrix2 {}

@expandMatrixType(order: 3)
public struct Matrix3 {}

@expandMatrixType(order: 4)
public struct Matrix4 {}

var someMatrix = Matrix3(
    1, 2, 3,
    4, 5, 6,
    7, 8, 9
)
print(someMatrix[1, 0])
print(someMatrix.determinant())
print(someMatrix.submatrix(row: 2, column: 2))
someMatrix[1, 0] = 42
print(someMatrix[1, 0])


var otherMatrix = Matrix4(
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 16
)
print(otherMatrix.determinant())
