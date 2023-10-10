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
    func testMatrixTypeMacro() throws {
        let originalSource = """
        @expandMatrixType(2)
        public struct Matrix2 {
        }
        """

        let expandedSource = """
        public struct Matrix2 {
        
            var data: (Double, Double, Double, Double)
        }
        """

        assertMacroExpansion(originalSource, expandedSource: expandedSource, macros: testMacros)
    }
}
