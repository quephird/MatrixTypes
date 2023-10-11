import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MatrixTypesMacros)
import MatrixTypesMacros

let testMacros: [String: Macro.Type] = [
    "expandMatrixType": MatrixTypeMacro.self,
]
#endif

final class MatrixTypesTests: XCTestCase {
    func testMacroForMatrixOfOrder2() throws {
        let originalSource = """
        @expandMatrixType(2)
        public struct Matrix2 {
        }
        """

        let expandedSource = """
        public struct Matrix2 {

            var data: (Double, Double, Double, Double)

            init(_ x0: Double, _ x1: Double, _ x2: Double, _ x3: Double) {
                self.data = (x0, x1, x2, x3)
            }

            subscript(row: Int, column: Int) -> Double {
                get {
                    let index = column + row * 2
                    switch index {
                    case 0:
                        return self.data.0
                    case 1:
                        return self.data.1
                    case 2:
                        return self.data.2
                    case 3:
                        return self.data.3
                    default:
                        fatalError()
                    }
                }
                set(newValue) {
                    let index = column + row * 2
                    switch index {
                    case 0:
                        self.data.0 = newValue
                    case 1:
                        self.data.1 = newValue
                    case 2:
                        self.data.2 = newValue
                    case 3:
                        self.data.3 = newValue
                    default:
                        fatalError()
                    }
                }
            }

            func determinant() -> Double {
                return self [0, 0] * self [1, 1] - self [0, 1] * self [1, 0]
            }
        }
        """

        assertMacroExpansion(originalSource, expandedSource: expandedSource, macros: testMacros)
    }

    func testMacroForMatrixOfOrder3() throws {
        let originalSource = """
        @expandMatrixType(3)
        public struct Matrix3 {
        }
        """

        let expandedSource = """
        public struct Matrix3 {

            var data: (Double, Double, Double, Double, Double, Double, Double, Double, Double)

            init(_ x0: Double, _ x1: Double, _ x2: Double, _ x3: Double, _ x4: Double, _ x5: Double, _ x6: Double, _ x7: Double, _ x8: Double) {
                self.data = (x0, x1, x2, x3, x4, x5, x6, x7, x8)
            }

            subscript(row: Int, column: Int) -> Double {
                get {
                    let index = column + row * 3
                    switch index {
                    case 0:
                        return self.data.0
                    case 1:
                        return self.data.1
                    case 2:
                        return self.data.2
                    case 3:
                        return self.data.3
                    case 4:
                        return self.data.4
                    case 5:
                        return self.data.5
                    case 6:
                        return self.data.6
                    case 7:
                        return self.data.7
                    case 8:
                        return self.data.8
                    default:
                        fatalError()
                    }
                }
                set(newValue) {
                    let index = column + row * 3
                    switch index {
                    case 0:
                        self.data.0 = newValue
                    case 1:
                        self.data.1 = newValue
                    case 2:
                        self.data.2 = newValue
                    case 3:
                        self.data.3 = newValue
                    case 4:
                        self.data.4 = newValue
                    case 5:
                        self.data.5 = newValue
                    case 6:
                        self.data.6 = newValue
                    case 7:
                        self.data.7 = newValue
                    case 8:
                        self.data.8 = newValue
                    default:
                        fatalError()
                    }
                }
            }

            func submatrix(row: Int, column: Int) -> Matrix2 {
                var sm = Matrix2(0, 0, 0, 0)
                var targetRow = 0
                for sourceRow in 0 ... 2 {
                    if sourceRow == row {
                        continue
                    }
                    var targetColumn = 0
                    for sourceColumn in 0 ... 2 {
                        if sourceColumn == column {
                            continue
                        }
                        sm[targetRow, targetColumn] = self [sourceRow, sourceColumn]
                        targetColumn += 1
                    }
                    targetRow += 1
                }
                return sm
            }

            func minor(row: Int, column: Int) -> Double {
                self.submatrix(row: row, column: column).determinant()
            }

            func cofactor(row: Int, column: Int) -> Double {
                let coefficient = (row + column) % 2 == 0 ? 1.0 : -1.0
                let minor = self.minor(row: row, column: column)
                return coefficient * minor
            }

            func determinant() -> Double {
                var value = 0.0
                for i in 0 ... 2 {
                    value += self.cofactor(row: 0, column: i) * self [0, i]
                }
                return value
            }
        }
        """

        assertMacroExpansion(originalSource, expandedSource: expandedSource, macros: testMacros)
    }
}
